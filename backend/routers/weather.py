import os
from datetime import datetime, timedelta

import httpx
from fastapi import APIRouter, HTTPException, Query

router = APIRouter()

_OPENWEATHER_BASE = "https://api.openweathermap.org/data/2.5/forecast"
_PHOTON_BASE = "https://photon.komoot.io/api/"

_MONTH_NAMES = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]


def _align_icon(api_icon: str, local_time: datetime) -> str:
    if len(api_icon) < 2:
        return api_icon
    is_night = local_time.hour < 6 or local_time.hour >= 20
    return api_icon[:-1] + ("n" if is_night else "d")


@router.get("/weather/city-suggestions")
async def get_city_suggestions(q: str = Query(..., min_length=2)):
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                _PHOTON_BASE,
                params={"q": q, "limit": 5, "layer": "city", "lang": "en"},
                headers={"User-Agent": "WardrobeMasterAI/1.0"},
                timeout=5.0,
            )
        if resp.status_code != 200:
            return {"suggestions": []}

        suggestions = []
        seen: set[str] = set()
        for feature in resp.json().get("features", []):
            props = feature.get("properties", {})
            city = props.get("name", "")
            country = props.get("country", "")
            if not city or not country:
                continue
            label = f"{city}, {country}"
            if label not in seen:
                seen.add(label)
                suggestions.append(label)

        return {"suggestions": suggestions}
    except Exception:
        return {"suggestions": []}


@router.get("/weather/current")
async def get_current_weather(lat: float = Query(...), lon: float = Query(...)):
    key = os.getenv("OPENWEATHER_API_KEY", "")
    if not key:
        raise HTTPException(status_code=500, detail="OPENWEATHER_API_KEY not configured")

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            _OPENWEATHER_BASE,
            params={"lat": lat, "lon": lon, "appid": key, "units": "metric"},
            timeout=15.0,
        )

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Failed to fetch weather data")

    data = resp.json()
    items = data.get("list", [])
    city_name = data.get("city", {}).get("name", "Unknown Location")

    if not items:
        raise HTTPException(status_code=502, detail="No weather data available")

    now = datetime.now()
    base_time = now.replace(minute=0, second=0, microsecond=0)
    current = items[0]

    forecast = []
    for i, item in enumerate(items[:9]):
        projected = base_time + timedelta(hours=i * 3)
        icon = _align_icon(item["weather"][0]["icon"], projected)
        forecast.append({
            "time_ms": int(projected.timestamp() * 1000),
            "time_label": projected.strftime("%H:00"),
            "temperature": round(item["main"]["temp"]),
            "condition": item["weather"][0]["main"],
            "icon_code": icon,
        })

    return {
        "city_name": city_name,
        "temperature": round(current["main"]["temp"]),
        "condition": current["weather"][0]["main"],
        "description": current["weather"][0]["description"],
        "icon_code": _align_icon(current["weather"][0]["icon"], base_time),
        "forecast": forecast,
    }


@router.get("/weather/trip-summary")
async def get_trip_weather_summary(
    destination: str = Query(...),
    start_date: str = Query(...),
    end_date: str = Query(...),
):
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")

    start_month = _MONTH_NAMES[start.month - 1]
    end_month = _MONTH_NAMES[end.month - 1]
    month_string = start_month if start.month == end.month else f"{start_month}/{end_month}"

    fallback = (
        f"Exact daily forecast unavailable. The trip takes place in {month_string}. "
        "Please rely on your general knowledge to use typical historical weather averages "
        "and temperature ranges for this destination during this time of year to plan the daily outfits."
    )

    days_until = (start.date() - datetime.now().date()).days
    if days_until > 5 or days_until < 0:
        return {"summary": fallback}

    key = os.getenv("OPENWEATHER_API_KEY", "")
    if not key:
        return {"summary": fallback}

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                _OPENWEATHER_BASE,
                params={"q": destination, "appid": key, "units": "metric"},
                timeout=15.0,
            )

        if resp.status_code != 200:
            return {"summary": fallback}

        items = resp.json().get("list", [])
        if not items:
            return {"summary": fallback}

        daily: dict = {}
        for item in items:
            dt = datetime.fromtimestamp(item["dt"])
            date_key = dt.strftime("%Y-%m-%d")
            display_date = f"{_MONTH_NAMES[dt.month - 1][:3]} {dt.day}"

            if dt.date() < start.date():
                continue
            if dt.date() > end.date():
                break

            temp = round(item["main"]["temp"])
            condition = item["weather"][0]["main"]

            if date_key not in daily:
                daily[date_key] = {
                    "display_date": display_date,
                    "max_temp": temp,
                    "conditions": {condition: 1},
                }
            else:
                if temp > daily[date_key]["max_temp"]:
                    daily[date_key]["max_temp"] = temp
                conds = daily[date_key]["conditions"]
                conds[condition] = conds.get(condition, 0) + 1

        if not daily:
            return {"summary": fallback}

        summaries = []
        for day_num, date_key in enumerate(sorted(daily.keys()), start=1):
            day = daily[date_key]
            dominant = max(day["conditions"], key=day["conditions"].get)
            summaries.append(f"Day {day_num} ({day['display_date']}): {day['max_temp']}°C, {dominant}")

        summary = ". ".join(summaries) + "."

        last_key = sorted(daily.keys())[-1]
        if datetime.strptime(last_key, "%Y-%m-%d").date() < end.date():
            summary += (
                "\nNote: Exact forecast for the remaining days of the trip is unavailable. "
                "Please rely on your general knowledge of typical historical weather averages "
                "for this destination during this time of year to complete the wardrobe selection."
            )

        return {"summary": summary}

    except Exception:
        return {"summary": fallback}
