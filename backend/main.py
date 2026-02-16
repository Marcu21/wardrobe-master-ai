from typing import Optional
from datetime import datetime
from fastapi import FastAPI, File, UploadFile, HTTPException
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

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)

app = FastAPI()

# Add CORS Middleware to allow requests from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
            model='gemini-flash-latest', 
            contents=request_contents,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        
        # Parse the JSON response
        # The new client might return a parsed object if response_mime_type is set, 
        # checking both response.parsed and response.text just in case.
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
