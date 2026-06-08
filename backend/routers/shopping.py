import json

from fastapi import APIRouter, HTTPException
from google.genai import types

from core.config import client
from models.schemas import OutfitGenerationRequest
from utils.gemini import parse_gemini_response

router = APIRouter()


@router.post("/generate-outfits/")
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

        ### EMPTY WARDROBE EXCEPTION
        - If the User's Wardrobe is completely empty (`[]`), you MUST NOT generate any outfits. The `outfits` array in the JSON response MUST be left completely empty (`[]`). Do NOT hallucinate items.
        - Evaluate the newly scanned item purely on its standalone versatility as a foundational wardrobe piece (e.g., a basic neutral tee is an excellent 90+ score starting piece, whereas a highly specific neon item might score lower since there's nothing to anchor it yet).
        - Acknowledge in the `pros` or `cons` that their digital wardrobe is currently empty, explaining whether this item is a solid foundational piece to start building upon.

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

        return parse_gemini_response(response)

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
