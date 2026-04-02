from typing import Optional, List, Dict, Any
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.concurrency import run_in_threadpool
from rembg import remove
from PIL import Image
import io
import os
import base64
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)

# Initialize Firebase Admin
if not firebase_admin._apps:
    # Use environment variable or default path for credentials
    cred_path = os.getenv("FIREBASE_CREDENTIALS", "firebase_credentials.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        # Fallback for when no credential file is present (e.g. dev environment without auth)
        # In a real scenario, this should likely fail or use application default credentials
        print(f"Warning: Firebase credentials not found at {cred_path}")
        # firebase_admin.initialize_app() # specific setup might be needed

db = firestore.client() if firebase_admin._apps else None

app = FastAPI()

# Add CORS Middleware to allow requests from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data Models
class OutfitRequest(BaseModel):
    user_prompt: str
    current_weather: str
    hourly_forecast: str
    user_id: str

class OutfitResponse(BaseModel):
    selected_item_ids: List[str]
    explanation: str

class ItemMetadata(BaseModel):
    item_id: str
    category: str
    sub_category: str
    primary_colors: List[str]
    style_occasions: List[str]
    seasonality: List[str]

class OutfitGenerationRequest(BaseModel):
    scanned_item: ItemMetadata
    wardrobe: List[ItemMetadata]

class PackingRequest(BaseModel):
    destination: str
    days: int
    vibe: str
    weather_forecast: str
    user_id: str

@app.post("/remove-bg/")
async def remove_background(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        # Read the file content
        contents = await file.read()
        
        # Open the image using Pillow
        input_image = Image.open(io.BytesIO(contents))
        
        # Remove the background
        output_image = await run_in_threadpool(remove, input_image)

        bbox = output_image.getbbox()
        if bbox:
            output_image = output_image.crop(bbox)
        
        # Save the result to a byte buffer
        img_byte_arr = io.BytesIO()
        output_image.save(img_byte_arr, format="PNG")
        img_byte_arr = img_byte_arr.getvalue()
        
        # Return the processed image
        return Response(content=img_byte_arr, media_type="image/png")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process-item/")
async def process_item(file: UploadFile = File(...), tag_file: Optional[UploadFile] = File(None)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    if not client:
         raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured in backend")

    try:
        # 1. Read and Process Image (Remove BG)
        contents = await file.read()
        input_image = Image.open(io.BytesIO(contents))
        output_image = await run_in_threadpool(remove, input_image)

        bbox = output_image.getbbox()
        if bbox:
            output_image = output_image.crop(bbox)
        
        # Convert processed image to base64 for response
        img_byte_arr = io.BytesIO()
        output_image.save(img_byte_arr, format="PNG")
        img_bytes = img_byte_arr.getvalue()
        image_base64 = base64.b64encode(img_bytes).decode('utf-8')

        # Convert RGBA to RGB for Gemini compatibility
        if output_image.mode == 'RGBA':
            analysis_image = output_image.convert('RGB')
        else:
            analysis_image = output_image

        # 2. Process Tag Image (if exists)
        tag_image = None
        if tag_file:
            tag_contents = await tag_file.read()
            tag_pil = Image.open(io.BytesIO(tag_contents))
            if tag_pil.mode == 'RGBA':
                tag_image = tag_pil.convert('RGB')
            else:
                tag_image = tag_pil

        current_date = datetime.now().strftime("%Y-%m-%d")
        
        prompt = f"""
        You are an elite textile technologist, master tailor, and fashion taxonomist.
        
        ### INPUTS:
        IMAGE 1: The clothing item.
        IMAGE 2: The laundry/care tag (OPTIONAL).

        ### STEP-BY-STEP ANALYSIS (Crucial for accuracy):
        1. TEXTURE & DRAPE: Examine Image 1 closely. Look at the weave, how the fabric reflects light (sheen), and how it folds. 
        2. TAG EXTRACTION: If Image 2 is present, read the exact material composition percentages first. 
        3. SYMBOL DECODING: If Image 2 is present, locate the horizontal row of ISO 3758 laundry pictograms. Ignore general text/numbers outside this row.

        ### STRICT TAXONOMY RULES:
        - "category" MUST be one of: Top, Bottom, Outerwear, Shoes, Accessories, Full Body.
        - "sub_category" MUST be highly specific (e.g., T-Shirt, Zip-up Hoodie, Pullover Hoodie, Sweater, Cardigan, Jeans, Chinos). Crucially, distinguish between open-front tops (like Zip-up Hoodies or Cardigans) and closed tops (like Pullover Hoodies).
        - "primary_colors": Use standard hex-compatible names (e.g., Navy Blue, Burgundy, Olive Green). Max 2 colors.
        - "material": If Tag is visible, extract exact composition (e.g., "80% Cotton, 20% Polyester"). If no tag, provide the single most accurate expert guess based on visual texture (e.g., "Cotton", "Linen", "Denim", "Wool"). NEVER output "Unknown".
        - "fit": Must be one of: Skinny, Slim, Regular, Relaxed, Oversized.
        
        ### METADATA RULES:
        - Brand: Extract from tag or logos. If none visible, use "Unbranded".
        - 'sustainability_info.purchase_date' MUST be exactly "{current_date}".
        - If IMAGE 2 is missing/unreadable, set 'laundry_info' to null. Do NOT hallucinate care instructions.
        
        ### RESPONSE FORMAT:
        Return ONLY a valid JSON object. Do not include markdown blocks like ```json.
        
        JSON Structure:
        {{
          "analysis_reasoning": "Briefly explain your visual findings: fabric texture, tag details, and symbol interpretations. Doing this first improves your accuracy.",
          "basic_info": {{
            "category": "String",
            "sub_category": "String",
            "primary_colors": ["String"],
            "material": "String",
            "pattern": "String (e.g., Solid, Striped, Plaid, Floral)"
          }},
          "styling_info": {{
            "fit": "String",
            "length": "String",
            "neckline": "String (or null)",
            "sleeve_length": "String (or null)",
            "style_occasions": ["String (e.g., Casual, Office, Formal, Sport)"],
            "seasonality": ["String (Spring, Summer, Autumn, Winter)"],
            "mood": ["String"]
          }},
          "laundry_info": {{
            "color_group": "String (Dark, Light, Color)",
            "max_temp_celsius": Integer (or null),
            "care_instructions": ["String (Translate the decoded ISO symbols here)"]
          }} OR null,
          "sustainability_info": {{
            "brand": "String",
            "price": 0.0,
            "currency": "RON",
            "purchase_date": "YYYY-MM-DD"
          }}
        }}
        """
        
        request_contents = [prompt, analysis_image]
        if tag_image:
            request_contents.append(tag_image)

        response = client.models.generate_content(
            model='gemini-flash-latest', 
            contents=request_contents,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        
        # Parse the JSON response
        if hasattr(response, 'parsed') and response.parsed:
             metadata = response.parsed
        else:
             metadata = json.loads(response.text)

        return {
            "image_base64": image_base64,
            "metadata": metadata
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-outfit/")
async def generate_outfit(request: OutfitRequest):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")
    
    if not db:
       raise HTTPException(status_code=500, detail="Firestore not initialized")

    try:
        # 1. Fetch Clothing Items from Firestore
        # In a real app, filtering by user_id would happen here
        clothing_ref = db.collection('clothing')
        docs = clothing_ref.stream()
        
        clothing_items = []
        for doc in docs:
            data = doc.to_dict()
            item_summary = {
                "id": doc.id,
                "category": data.get('basic_info', {}).get('category'),
                "sub_category": data.get('basic_info', {}).get('sub_category'),
                "primary_colors": data.get('basic_info', {}).get('primary_colors'),
                "brand": data.get('sustainability_info', {}).get('brand', 'Unknown brand'),
                "material": data.get('basic_info', {}).get('material'),
                "fit": data.get('styling_info', {}).get('fit'),
                "style_occasions": data.get('styling_info', {}).get('style_occasions'),
                "seasonality": data.get('styling_info', {}).get('seasonality'),
            }
            clothing_items.append(item_summary)

        if not clothing_items:
             return {
                "selected_item_ids": [],
                "explanation": "No clothing items found in your wardrobe. Please add some items first."
            }

        clothing_json = json.dumps(clothing_items)
        
        prompt = f"""
        You are an elite personal stylist and wardrobe manager.
        
        ### CONTEXT
        User Plan: "{request.user_prompt}"
        Current Weather: "{request.current_weather}"
        Hourly Forecast: "{request.hourly_forecast}"
        
        ### INSTRUCTIONS
        1. Select the best possible outfit from the available 'CLOTHING ITEMS' list below.
        2. You MUST provide a COMPLETE outfit. A complete outfit ALWAYS includes at least one top, one bottom (pants, jeans, shorts, skirt), and shoes. Never return an outfit without a bottom!
        3. LAYERING STRATEGY: Analyze the hourly forecast. If it is cold, raining, or snowing, you MUST recommend layered clothing. 
        CRITICAL: It is highly encouraged to use "Summer" or "Spring" items (like t-shirts or thin tops) as BASE LAYERS underneath "Autumn" or "Winter" outerwear (like hoodies, sweaters, jackets, or coats). Do not exclude a t-shirt just because it is cold outside, as long as you pair it with warm outerwear.
        4. In your 'explanation', refer to items naturally by their Color, Brand, and Sub-category (e.g., "your black Nike t-shirt" or "the blue Zara jeans").
        5. CRITICAL RULE: NEVER include the raw database IDs in the 'explanation' text. The IDs must ONLY be placed inside the 'selected_item_ids' array.
        6. COLOR THEORY: Ensure the selected items match aesthetically. Avoid clashing colors. Favor neutral bases (black, white, grey, navy, beige) with maximum one or two accent colors.
        7. VISIBLE VS. HIDDEN LAYERING: If you want to showcase a T-shirt as a key visual part of the outfit, you MUST pair it with an open-front layer (e.g., "Zip-up Hoodie", "Cardigan", "Jacket", "Overshirt"). If you pair a T-shirt with a closed top (e.g., "Pullover Hoodie", "Sweater"), you must treat the T-shirt purely as a hidden thermal base layer in your explanation, not as a visual centerpiece.

        ### CLOTHING ITEMS
        {clothing_json}
        
        ### RESPONSE FORMAT
        Return ONLY a valid JSON object matching this schema:
        {{
          "selected_item_ids": ["id1", "id2", "id3"],
          "explanation": "Why this outfit works..."
        }}
        """
        
        # 3. Call Gemini
        response = client.models.generate_content(
            model='gemini-flash-latest', 
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        
        # 4. Return Parsed Response
        if hasattr(response, 'parsed') and response.parsed:
             result = response.parsed
        else:
             result = json.loads(response.text)
             
        return result

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-outfits/")
async def generate_outfits(request: OutfitGenerationRequest):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")
    
    try:
        scanned_item_json = request.scanned_item.model_dump_json()
        wardrobe_json = json.dumps([item.model_dump() for item in request.wardrobe])
        
        prompt = f"""
        You are an expert, pragmatic personal fashion stylist and smart-shopping advisor. Your goal is to protect the user's wallet from redundant purchases, color clashes, and style mismatches, while encouraging highly versatile items that build a cohesive wardrobe.
        
        ### CONTEXT
        - Newly Scanned Item: {scanned_item_json}
        - User's Wardrobe: {wardrobe_json}
        
        ### MANDATORY OUTFIT RULES
        1. COMPLETE LOOKS ONLY: Each outfit must be a functional, full look.
           - If Scanned Item is a TOP/OUTERWEAR: Add 1 Bottom and 1 Pair of Shoes.
           - If Scanned Item is a BOTTOM: Add 1 Top and 1 Pair of Shoes.
           - If Scanned Item is SHOES: Add 1 Top and 1 Bottom.
        2. THE ZIP-UP RULE: If the "Newly Scanned Item" is a 'Zip-up Hoodie' (or any hoodie with a zipper), you MUST add a T-shirt underneath it.
        3. REALISTIC LAYERING LOGIC (CRITICAL): NEVER suggest layering thick items over each other. You cannot layer a hoodie under another hoodie, or a thick sweater under a hoodie. Only layer thin items (like t-shirts) under midwear/outerwear.
        
        ### STRICT SCORING SYSTEM (0-100) & PENALTIES
        Calculate the 'score' based on these 3 critical shopping rules:
        
        1. THE CLONE PENALTY (Sub-category + Color): This is your most strict rule. Check the user's wardrobe for the exact same `sub_category` AND `primary_colors`. If the scanned item is a "Black T-shirt" and the user already owns a "Black T-shirt", the score MUST drop below 50. There is no reason to buy duplicates.
        
        2. THE ISOLATED COLOR CLASH: If the scanned item is a bright, loud, or highly specific color, check if the wardrobe has complementary colors or grounding neutrals to style it. CRITICAL RULE: DO NOT compare tops with other tops, or bottoms with other bottoms for color clashing (because they wouldn't be worn together anyway)! ONLY evaluate if a scanned TOP matches the user's BOTTOMS/SHOES, or if a scanned BOTTOM matches the user's TOPS/SHOES. If it cannot form at least 1-2 good outfits with opposite categories, drop the score below 55.
        
        3. THE GENRE MISMATCH: Compare the item's `style_occasions` and general vibe with the wardrobe. If the scanned item is e.g., strictly "Formal" but the wardrobe is entirely "Streetwear/Sport", and they cannot be mixed cleanly, drop the score below 50.
        
        - SCORE RANGES:
          * 85-100: Perfect addition. Fills a gap, unique color/sub-category, highly versatile.
          * 65-84: Solid item. Makes good outfits, maybe overlaps slightly with their style but brings a new color/texture.
          * 45-64: Hard to justify. Major color/style clash, or they already own something very similar.
          * Below 45: DO NOT BUY. Exact clone (same color + same sub_category) OR completely unstylable with their current clothes.

        ### INSTRUCTIONS
        1. Generate exactly 3 outfit combinations ONLY IF the item is versatile enough. If it's a terrible match, generate only 1 or 2 outfits.
        2. Be highly pragmatic. If it's a clone, tell them strictly in the "cons" not to waste money.
        3. WARDROBE REALISM: A good item only needs to form 1-3 solid outfits. Do NOT expect a new item to match 100% of the user's wardrobe. 
        
        ### STYLING RULES FOR REASONING (Pros & Cons):
        - DO NOT mention technical Item IDs. Use natural descriptions (e.g., "your black slim-fit jeans").
        - "Pros" should highlight versatility and how it elevates their current style.
        - "Cons" must explicitly state if the item is a clone ("You already own a black t-shirt").
        - CRITICAL FOR CONS: NEVER complain that an item doesn't match another item of the same category (e.g., do not say a new hoodie clashes with an old hoodie, you only wear one at a time). 
        - CRITICAL FOR CONS: NEVER complain that the scanned item doesn't match the *entire* wardrobe. If it forms good outfits with their jeans/sneakers, do not mention that it clashes with a random purple item they own.
        
        ### RESPONSE FORMAT
        Return ONLY a valid JSON object matching this schema:
        {{
          "score": 42,
          "pros": ["Comfortable fit"],
          "cons": ["You already own a black t-shirt. Buying another one is redundant.", "Doesn't elevate your current wardrobe."],
          "outfits": [
            {{
              "outfit_name": "Basic Everyday",
              "styling_notes": "We paired it with your blue jeans, but honestly, your current black shirt does the exact same job.",
              "item_ids": ["scanned_new_item", "wardrobe_id_1", "wardrobe_id_2"]
            }}
          ]
        }}
        """
        
        response = client.models.generate_content(
            model='gemini-flash-latest', 
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        
        if hasattr(response, 'parsed') and response.parsed:
             result = response.parsed
        else:
             result = json.loads(response.text)
             
        return result

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-packing/")
async def generate_packing(request: PackingRequest):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")
    
    if not db:
       raise HTTPException(status_code=500, detail="Firestore not initialized")

    try:
        # 1. Fetch Clothing Items from Firestore
        # In a real app, you would filter by request.user_id here
        clothing_ref = db.collection('clothing')
        docs = clothing_ref.stream()
        
        clothing_items = []
        for doc in docs:
            data = doc.to_dict()
            item_summary = {
                "id": doc.id,
                "category": data.get('basic_info', {}).get('category'),
                "sub_category": data.get('basic_info', {}).get('sub_category'),
                "primary_colors": data.get('basic_info', {}).get('primary_colors'),
                "material": data.get('basic_info', {}).get('material'),
                "style_occasions": data.get('styling_info', {}).get('style_occasions'),
                "seasonality": data.get('styling_info', {}).get('seasonality'),
            }
            clothing_items.append(item_summary)

        if not clothing_items:
             return {
                "selected_item_ids": [],
                "reasoning": "No clothing items found in your wardrobe.",
                "outfits": []
            }

        clothing_json = json.dumps(clothing_items)
        
        prompt = f"""
        You are an elite travel stylist. 
        The user is packing for a trip to {request.destination} for {request.days} days. 
        The trip vibe/purpose is '{request.vibe}'.
        
        ### WEATHER FORECAST:
        {request.weather_forecast}
        
        ### USER WARDROBE:
        {clothing_json}
        
        ### INSTRUCTIONS:
        1. Create a "Capsule Wardrobe" from the user's wardrobe. Select a minimal number of highly versatile items that mix and match well.
        2. Ensure the colors coordinate and the materials fit the destination/vibe.
        3. Using ONLY the items you selected for the capsule wardrobe, generate {request.days} distinct daily outfits.
        4. NEVER include the raw database IDs in the text descriptions. IDs must only be in the arrays.
        5. Each outfit must be a complete look (must have a top, a bottom, and shoes).
        
        ### RESPONSE FORMAT:
        Return ONLY a valid JSON object matching this schema:
        {{
          "selected_item_ids": ["id1", "id2", "id3", "id4", "id5"],
          "reasoning": "Explain concisely why you chose this capsule wardrobe for the destination and vibe.",
          "outfits": [
            {{
              "title": "Day 1: Arrival & Exploring",
              "description": "A comfortable but stylish look for walking around...",
              "item_ids": ["id1", "id3", "id5"]
            }}
          ]
        }}
        """
        
        response = client.models.generate_content(
            model='gemini-flash-latest', 
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        
        if hasattr(response, 'parsed') and response.parsed:
             result = response.parsed
        else:
             result = json.loads(response.text)
             
        return result

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
