import json
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from google.genai import types

from core.config import client, db
from core.dependencies import get_verified_uid
from models.schemas import OutfitRequest
from utils.gemini import parse_gemini_response

router = APIRouter()


@router.post("/generate-outfit/")
async def generate_outfit(request: OutfitRequest, uid: str = Depends(get_verified_uid)):
    if not client:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")

    if not db:
        raise HTTPException(status_code=500, detail="Firestore not initialized")

    try:
        now = datetime.now(timezone.utc)
        seven_days_ago = now - timedelta(days=7)

        # Fetch Clothing Items from Firestore
        clothing_ref = db.collection('clothing').where(filter=FieldFilter('userId', '==', uid))
        if request.wardrobe_id:
            clothing_ref = clothing_ref.where(filter=FieldFilter('wardrobe_id', '==', request.wardrobe_id))
        docs = clothing_ref.stream()

        clothing_items = []
        for doc in docs:
            data = doc.to_dict()

            category = data.get('basic_info', {}).get('category')
            sub_category = data.get('basic_info', {}).get('sub_category')

            days_since = 0
            last_worn = data.get('last_worn')
            if isinstance(last_worn, datetime):
                lw = last_worn if last_worn.tzinfo else last_worn.replace(tzinfo=timezone.utc)
                days_since = (now - lw).days
            else:
                purchase_date_str = data.get('sustainability_info', {}).get('purchase_date')
                if purchase_date_str:
                    try:
                        purchase_date = datetime.strptime(purchase_date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
                        days_since = (now - purchase_date).days
                    except ValueError:
                        pass

            is_exempt = category == 'Outerwear' or (
                sub_category and ('jacket' in sub_category.lower() or 'coat' in sub_category.lower())
            )
            is_neglected = not is_exempt and days_since > 45

            item_summary = {
                "id": doc.id,
                "category": category,
                "sub_category": sub_category,
                "primary_colors": data.get('basic_info', {}).get('primary_colors'),
                "brand": data.get('sustainability_info', {}).get('brand', 'Unknown brand'),
                "material": data.get('basic_info', {}).get('material'),
                "fit": data.get('styling_info', {}).get('fit'),
                "style_occasions": data.get('styling_info', {}).get('style_occasions'),
                "seasonality": data.get('styling_info', {}).get('seasonality'),
            }
            if request.prioritize_neglected and is_neglected:
                item_summary["rotation_status"] = "Neglected"
            clothing_items.append(item_summary)

        if not clothing_items:
            return {
                "selected_item_ids": [],
                "explanation": "No clothing items found in your wardrobe. Please add some items first."
            }

        clothing_json = json.dumps(clothing_items)

        # Fetch Recent Outfits
        recent_outfits_stream = db.collection('outfits').where(filter=FieldFilter('user_id', '==', uid)).stream()
        recent_outfit_ids = []
        for outfit_doc in recent_outfits_stream:
            outfit_data = outfit_doc.to_dict()
            wear_dates = outfit_data.get('wear_dates', [])
            item_ids = outfit_data.get('item_ids', [])

            if not item_ids:
                continue

            is_recent = False
            for wear_date in wear_dates:
                if isinstance(wear_date, datetime):
                    wd = wear_date if wear_date.tzinfo else wear_date.replace(tzinfo=timezone.utc)
                    if wd >= seven_days_ago:
                        is_recent = True
                        break
                elif isinstance(wear_date, str):
                    try:
                        wd = datetime.fromisoformat(wear_date.replace('Z', '+00:00'))
                        wd = wd if wd.tzinfo else wd.replace(tzinfo=timezone.utc)
                        if wd >= seven_days_ago:
                            is_recent = True
                            break
                    except ValueError:
                        pass
            if is_recent:
                recent_outfit_ids.append(item_ids)

        recent_outfits_json = json.dumps(recent_outfit_ids)

        # Fetch Outfit Feedback
        try:
            feedback_ref = db.collection('outfit_feedback').where(
                filter=FieldFilter('user_id', '==', uid)
            ).order_by('created_at', direction=firestore.Query.DESCENDING).limit(15)

            feedback_docs = feedback_ref.stream()
            feedback_history_strs = []
            for doc in feedback_docs:
                data = doc.to_dict()
                is_like = data.get('is_like')
                item_ids = data.get('item_ids', [])
                user_prompt_fb = data.get('user_prompt', '')
                weather_fb = data.get('weather_context', '')
                dislike_reason = data.get('dislike_reason', '')

                if is_like:
                    feedback_history_strs.append(f"User LIKED combining items {item_ids} for plan '{user_prompt_fb}' and weather '{weather_fb}'.")
                else:
                    feedback_history_strs.append(f"User DISLIKED combining items {item_ids} for plan '{user_prompt_fb}' and weather '{weather_fb}'. Reason: {dislike_reason}.")

            feedback_history_text = "\n".join(feedback_history_strs) if feedback_history_strs else "No feedback history available yet."
        except Exception as e:
            print(f"Warning: Failed to fetch outfit feedback: {e}")
            feedback_history_text = "No feedback history available yet."

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

        8. TIME & DURATION AWARENESS: Pay strict attention to the current time and the likely duration of the user's requested activity.
        9. IMMEDIATE WEATHER PRIORITY: If the user is doing a short activity NOW (e.g., jogging, a quick errand), base the outfit STRICTLY on the current/immediate weather conditions (next 1-2 hours). Do NOT incorporate heavy layers for drastic weather changes (like rain or temperature drops) that happen many hours after the activity would normally end.
        10. FUTURE WEATHER WARNINGS (CRUCIAL RULE): If there is a significant weather change later in the day (e.g., temperature drop, rain), DO NOT change the immediate outfit to accommodate it if the activity is short. Instead, provide the light/immediate outfit and simply add a friendly warning in your explanation. Example: "Since you're going jogging now, this light outfit is perfect for the 27°C heat. However, if you plan to stay out until 20:00, be aware that the temperature will drop to 12°C with rain, so you might want to pack a zip-up hoodie just in case."

        11. CRITICAL AI INSTRUCTION: Be a critical fashion judge. Do not award 100/100 easily. Provide realistic scores. Ensure no tags or jargon arrays are requested or generated.

        ### RECENT HISTORY
        Recent Outfit IDs: {recent_outfits_json}
        This is a list of item IDs the user wore together recently. CRITICAL RULE: Do NOT recommend these exact combinations of IDs again. It is PERFECTLY FINE to reuse an individual piece (e.g., you can reuse a Top OR a Bottom from a few days ago), but the WHOLE outfit must not be the same. Specifically, the core combination (Top + Bottom) MUST be different from recent history. EXCEPTION: It is 100% acceptable to reuse the exact same Shoes and Outerwear IDs, just ensure the core outfit (Top + Bottom) underneath is fresh.

        {"""### WARDROBE ROTATION
        Look at the 'CLOTHING ITEMS' list. Some items have a 'rotation_status' of 'Neglected'. You MUST prioritize including at least ONE neglected item in your generated outfit, BUT ONLY IF it perfectly matches the weather forecast, the color theory, and the user's plan. Do not force a neglected item if it ruins the outfit.""" if request.prioritize_neglected else ""}

        ### USER PREFERENCES & RESTRICTIONS
        {feedback_history_text}
        CRITICAL: Carefully analyze the USER PREFERENCES & RESTRICTIONS. If the user previously DISLIKED a combination for a specific context or weather, DO NOT recommend that exact combination again for similar conditions, keeping their 'Reason' in mind. If they LIKED a combination, use that as strong inspiration for their personal style.

        ### CLOTHING ITEMS
        {clothing_json}

        ### RESPONSE FORMAT
        Return ONLY a valid JSON object matching this schema:
        {{
          "selected_item_ids": ["id1", "id2", "id3"],
          "overall_score": 85,
          "scores": {{
            "style_match": 80,
            "weather_match": 90,
            "context_match": 85,
            "color_harmony": 85
          }},
          "explanation": "Why this outfit works..."
        }}
        """

        # Call Gemini
        response = client.models.generate_content(
            model='gemini-flash-latest',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json',
                response_schema={
                    'type': 'OBJECT',
                    'properties': {
                        'selected_item_ids': {
                            'type': 'ARRAY',
                            'items': {'type': 'STRING'},
                        },
                        'overall_score': {'type': 'INTEGER'},
                        'scores': {
                            'type': 'OBJECT',
                            'properties': {
                                'style_match':   {'type': 'INTEGER'},
                                'weather_match': {'type': 'INTEGER'},
                                'context_match': {'type': 'INTEGER'},
                                'color_harmony': {'type': 'INTEGER'},
                            },
                        },
                        'explanation': {'type': 'STRING'},
                    },
                    'required': [
                        'selected_item_ids', 'overall_score',
                        'scores', 'explanation',
                    ],
                },
            ),
        )

        return parse_gemini_response(response)

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
