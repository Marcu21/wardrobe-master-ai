from typing import Optional, List, Dict, Any
from pydantic import BaseModel


class OutfitRequest(BaseModel):
    user_prompt: str
    current_weather: str
    hourly_forecast: str
    wardrobe_id: Optional[str] = None
    prioritize_neglected: bool = True


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
    wardrobe_id: Optional[str] = None
    item_ids_override: Optional[List[str]] = None
    trip_plans: Optional[str] = None
    luggage_size: Optional[str] = None


class TripOutfitRequest(BaseModel):
    destination: str
    vibe: str
    weather_forecast: str
    suitcase_item_ids: List[str]
    user_context: str
    existing_outfits: Optional[List[Dict[str, Any]]] = None
    feedback: Optional[str] = None
    current_outfit_item_ids: Optional[List[str]] = None
