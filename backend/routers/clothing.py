import io
import base64
import json
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import Response
from google.genai import types
from PIL import Image
from rembg import remove

from core.config import client

router = APIRouter()


@router.post("/remove-bg/")
async def remove_background(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        contents = await file.read()
        input_image = Image.open(io.BytesIO(contents))
        output_image = await run_in_threadpool(remove, input_image)

        bbox = output_image.getbbox()
        if bbox:
            output_image = output_image.crop(bbox)

        img_byte_arr = io.BytesIO()
        output_image.save(img_byte_arr, format="PNG")
        img_byte_arr = img_byte_arr.getvalue()

        return Response(content=img_byte_arr, media_type="image/png")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/process-item/")
async def process_item(file: UploadFile = File(...), tag_file: Optional[UploadFile] = File(None)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured in backend")

    try:
        contents = await file.read()
        input_image = Image.open(io.BytesIO(contents))
        output_image = await run_in_threadpool(remove, input_image)

        bbox = output_image.getbbox()
        if bbox:
            output_image = output_image.crop(bbox)

        img_byte_arr = io.BytesIO()
        output_image.save(img_byte_arr, format="PNG")
        img_bytes = img_byte_arr.getvalue()
        image_base64 = base64.b64encode(img_bytes).decode('utf-8')

        if output_image.mode == 'RGBA':
            analysis_image = output_image.convert('RGB')
        else:
            analysis_image = output_image

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
        - ALWAYS return the 'laundry_info' object.
        - Deduce 'laundry_info.color_group' visually from IMAGE 1.
        - If IMAGE 2 is missing/unreadable (or if the item is Shoes), set 'laundry_info.max_temp_celsius' to a safe default (e.g., 30).
        - If IMAGE 2 is missing/unreadable, set 'laundry_info.care_instructions' to an empty array []. Do NOT hallucinate care instructions.

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
            "max_temp_celsius": Integer,
            "care_instructions": ["String (Translate the decoded ISO symbols here)"]
          }},
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
