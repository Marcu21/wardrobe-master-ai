from typing import Optional, List, Dict, Any
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
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
        output_image = remove(input_image)

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
        output_image = remove(input_image)

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
        Analyze the provided image(s) as a textile care expert.
        IMAGE 1: The clothing item.
        IMAGE 2: The laundry/care tag (OPTIONAL).

        ### PROCESSING PRIORITIES:
        1. If IMAGE 2 is present, locate the horizontal row of international laundry care symbols (ISO 3758 pictograms).
        2. Completely ignore all numbers and text OUTSIDE of that specific symbols row (especially sizes like 30, 32, 40, etc.); these pictograms take absolute priority over any general text on the tag.
        3. Interpret EVERY symbol present in that specific row (washing, bleaching, drying, ironing, and professional care).
        4. MATERIAL ANALYSIS: You MUST provide a material composition. NEVER return "Unknown". 
           - Search for composition text on IMAGE 2 first. 
           - If IMAGE 2 is missing or unreadable, analyze the visual texture, weave, and drape of the garment in IMAGE 1. 
           - Provide only the most likely material name (e.g., "Cotton", "Polyester", "Wool", "Denim").
        5. If IMAGE 2 is NOT present, set 'laundry_info' to null. NEVER guess care instructions from Image 1.

        ### METADATA RULES:
        - Identify category, sub_category, and primary_colors from Image 1.
        - Identify brand from Image 2 (if visible) or Image 1 (logos).
        - Material: Follow the "MATERIAL ANALYSIS" rule above for a clean string response.
        - Set 'sustainability_info.purchase_date' to exactly "{current_date}".
        - Return ONLY a valid JSON object.
        
        JSON Structure:
        {{
          "basic_info": {{
            "category": "String (e.g. Top, Bottom, Shoes)",
            "sub_category": "String (e.g. T-Shirt, Jeans, Sneakers)",
            "primary_colors": ["String"],
            "material": "String",
            "pattern": "String"
          }},
          "styling_info": {{
            "fit": "String (e.g. Regular, Slim, Oversized)",
            "length": "String",
            "neckline": "String (if applicable)",
            "sleeve_length": "String (if applicable)",
            "style_occasions": ["String"],
            "seasonality": ["String"],
            "mood": ["String"]
          }},
          "laundry_info": {{
            "color_group": "String (Dark, Light, Color)",
            "max_temp_celsius": Integer (estimate based on material),
            "care_instructions": ["String"]
          }} OR null,
          "sustainability_info": {{
            "brand": "String (guess if visible, else Unknown)",
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
            model='gemini-flash-lite-latest', 
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
                "brand": data.get('sustainability_info', {}).get('brand', 'Unknown brand'), # <--- AM ADAUGAT BRANDUL AICI
                "material": data.get('basic_info', {}).get('material'),
                "fit": data.get('styling_info', {}).get('fit'),
                "style_occasions": data.get('styling_info', {}).get('style_occasions'),
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
        3. Analyze the hourly forecast. If the temperature drops or weather worsens, recommend layered clothing.
        4. In your 'explanation', refer to items naturally by their Color, Brand, and Sub-category (e.g., "your black Nike t-shirt" or "the blue Zara jeans").
        5. CRITICAL RULE: NEVER include the raw database IDs in the 'explanation' text. The IDs must ONLY be placed inside the 'selected_item_ids' array.
        
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
