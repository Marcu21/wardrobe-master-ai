import json

from fastapi import APIRouter, Depends, HTTPException
from google.cloud.firestore_v1.base_query import FieldFilter
from google.genai import types

from core.config import client, db
from core.dependencies import get_verified_uid
from models.schemas import PackingRequest, TripOutfitRequest
from utils.gemini import parse_gemini_response

router = APIRouter()


@router.post("/generate-packing/")
async def generate_packing(request: PackingRequest, uid: str = Depends(get_verified_uid)):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")

    if not db:
        raise HTTPException(status_code=500, detail="Firestore not initialized")

    try:
        # Fetch Clothing Items from Firestore
        clothing_ref = db.collection('clothing').where(filter=FieldFilter('userId', '==', uid))
        if request.wardrobe_id:
            clothing_ref = clothing_ref.where(filter=FieldFilter('wardrobe_id', '==', request.wardrobe_id))
        docs = clothing_ref.stream()

        clothing_items = []
        for doc in docs:
            if request.item_ids_override is not None and doc.id not in request.item_ids_override:
                continue

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
        """

        if request.luggage_size:
            prompt += f"\n### LUGGAGE CONSTRAINT:\n"
            prompt += f"The user is traveling with a {request.luggage_size}.\n"
            if request.luggage_size == "Backpack":
                prompt += "CRITICAL: Restrict the suitcase to 6-8 items total. Be extremely minimalist.\n"
            elif request.luggage_size == "Carry-on":
                prompt += "CRITICAL: Aim for a standard capsule of 10-14 items total.\n"
            elif request.luggage_size == "Checked Bag":
                prompt += "CRITICAL: Prioritize comfort and variety. No strict limit.\n"

        if request.trip_plans:
            prompt += f"\n### TRIP PLANS & ITINERARY:\n{request.trip_plans}\n"

        prompt += f"""
        ### WEATHER FORECAST:
        {request.weather_forecast}

        ### USER WARDROBE {"(LOCKED TO SPECIFIC ITEMS)" if request.item_ids_override else ""}:
        {clothing_json}
        """

        if request.item_ids_override:
            prompt += """
        CRITICAL: You are provided with a specific list of items that are already in the user's suitcase. You MUST generate the daily outfits using ONLY these items. Do not suggest adding anything else.
        If the provided items are insufficient to create complete outfits (e.g., the user removed all pants or shoes), you must include a 'warning_message' field explaining what is missing. Otherwise, leave it as null or omit it.
        """

        prompt += f"""
        ### INSTRUCTIONS:
        1. Create a "Capsule Wardrobe" from the user's wardrobe. Select a minimal number of highly versatile items that mix and match well.
        2. Ensure the colors coordinate and the materials fit the destination/vibe.
        3. Using ONLY the items you selected for the capsule wardrobe, generate roughly {request.days} distinct outfits.
        4. CRITICAL INSTRUCTION: Do NOT label outfits as 'Day 1', 'Day 2', etc. The user wants a flexible capsule wardrobe. Instead, generate descriptive titles based on the provided `trip_plans` or vibe (e.g., 'Museum Explorer', 'Elegant Dinner Outfit'). Keep the focus on the occasion, not the calendar day.
        5. NEVER include the raw database IDs in the text descriptions. IDs must only be in the arrays.
        6. IF you have sufficient items, each generated outfit must be a complete look (top, bottom, shoes) using ONLY the provided items.
        7. CRITICAL RULE ON HALLUCINATIONS: You are strictly forbidden from 'supplementing' or inventing items that are not in the provided WARDROBE list. If the user's wardrobe does not contain the minimum required items to form at least one complete outfit (e.g., they have no bottoms or no shoes), you MUST do the following:
           - Set the `warning_message` field to explicitly state which essential clothing categories are missing from their wardrobe to pack for this trip.
           - Return an empty array `[]` for the `outfits` list. Do NOT generate incomplete outfits and do NOT hallucinate fake items in descriptions.
           - You may still select the items they DO have (e.g., their only T-shirt) in `selected_item_ids` and write the `reasoning` based on what little they own.

        ### RESPONSE FORMAT:
        Return ONLY a valid JSON object matching this schema:
        {{
          "selected_item_ids": ["id1", "id2", "id3", "id4", "id5"],
          "reasoning": "Explain concisely why you chose this capsule wardrobe for the destination and vibe.",
          "warning_message": "String warning if essential items are missing, else null.",
          "outfits": [
            {{
              "title": "Museum Explorer",
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

        return parse_gemini_response(response)

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-trip-outfit/")
async def generate_trip_outfit(request: TripOutfitRequest, uid: str = Depends(get_verified_uid)):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")

    if not db:
        raise HTTPException(status_code=500, detail="Firestore not initialized")

    try:
        if not request.suitcase_item_ids:
            raise HTTPException(status_code=400, detail="suitcase_item_ids cannot be empty")

        # Fetch Clothing Items from Firestore
        clothing_ref = db.collection('clothing').where(filter=FieldFilter('userId', '==', uid))
        docs = clothing_ref.stream()

        clothing_items = []
        for doc in docs:
            if doc.id not in request.suitcase_item_ids:
                continue

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
            raise HTTPException(status_code=400, detail="None of the provided suitcase items were found.")

        clothing_json = json.dumps(clothing_items)
        existing_outfits_json = json.dumps(request.existing_outfits) if request.existing_outfits else "[]"

        edit_context_block = ""
        if request.feedback:
            edit_context_block = f"""
        ### EDIT FEEDBACK (CRITICAL INSTRUCTION)
        The user wants to CHANGE their current outfit for this occasion.
        CURRENT OUTFIT ITEM IDs: {request.current_outfit_item_ids}
        USER'S COMPLAINT/FEEDBACK: "{request.feedback}"
        INSTRUCTION: You MUST address this feedback directly. Swap or remove items from the CURRENT OUTFIT using ONLY the SUITCASE WARDROBE to fix the user's issue. Do not completely ignore the current items if some still work, but make sure the final result respects the feedback!
        """

        prompt = f"""
        You are an elite travel stylist.
        The user is currently packing or has packed for a trip to {request.destination}.
        The overall trip vibe is '{request.vibe}'.
        Weather Forecast: {request.weather_forecast}

        The user needs an outfit for a specific occasion or day plan:
        USER CONTEXT/PLAN: "{request.user_context}"

        {edit_context_block}

        ### SUITCASE WARDROBE (CRITICAL CONSTRAINT)
        {clothing_json}

        ### EXISTING OUTFITS HISTORY
        CONTEXT: The user has already planned other outfits for this trip using specific items from the suitcase. Here is the history:
        {existing_outfits_json}

        ### STRICT RULES:
        1. You MUST generate exactly ONE complete outfit using ONLY the items provided in the SUITCASE WARDROBE above.
        2. NEVER hallucinate, invent, or suggest any clothing items that are not in the provided JSON list. If you need pants and there are no pants, do the best you can or mention it in the description, but DO NOT make up item IDs.
        3. The outfit MUST be suitable for the user's specific context/plan. If the user provides different contexts, try to be creative and provide distinct combinations of items, even if the events have a similar formality level. Do not just pick the safest outfit every time. Play with layering or different style combinations using ONLY the provided items.
        4. CRITICAL INSTRUCTION: You MUST cross-reference the `used_item_ids` from the history with the suitcase inventory. Do NOT suggest the exact same combination of `item_ids` for the new outfit. Maximize the rotation of clothes. If an item_id was heavily used in the history, prioritize different item_ids from the suitcase for this new outfit, unless absolutely necessary.
        5. Generate a concise, catchy 'title' for this specific outfit based on the user's context (e.g., "Gala Dinner Setup", "Rainy Museum Day", "Hiking in the Mountains").
        6. NEVER include the raw database IDs in the text description. IDs must only be in the array.

        ### RESPONSE FORMAT:
        Return ONLY a valid JSON object matching this schema:
        {{
          "title": "String - The catchy title you generated",
          "description": "String - Explain why this outfit works perfectly for their specific plan and how it addresses their feedback if any.",
          "item_ids": ["id1", "id2"]
        }}
        """

        response = client.models.generate_content(
            model='gemini-flash-latest',
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.85,
                response_mime_type='application/json'
            )
        )

        return parse_gemini_response(response)

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
