"""
Backend API tests — validates input contracts, authentication enforcement,
and error handling without requiring live Firebase or Gemini credentials.
"""
import sys
from unittest.mock import MagicMock

# ── Stubs: must be registered before any app import ─────────────────────────

# firebase_admin
_firebase_stub = MagicMock()
_firebase_stub._apps = {"[DEFAULT]": MagicMock()}
_firebase_stub.auth.verify_id_token.return_value = {"uid": "test-uid-123"}
sys.modules["firebase_admin"] = _firebase_stub
sys.modules["firebase_admin.auth"] = _firebase_stub.auth
sys.modules["firebase_admin.credentials"] = _firebase_stub.credentials
sys.modules["firebase_admin.firestore"] = _firebase_stub.firestore

# google — must stub the top-level namespace so `from google import genai` works
_genai_stub = MagicMock()
_genai_types_stub = MagicMock()
_genai_stub.types = _genai_types_stub

_base_query_stub = MagicMock()
_firestore_v1_stub = MagicMock()
_firestore_v1_stub.base_query = _base_query_stub

_google_stub = MagicMock()
_google_stub.genai = _genai_stub

sys.modules["google"] = _google_stub
sys.modules["google.genai"] = _genai_stub
sys.modules["google.genai.types"] = _genai_types_stub
sys.modules["google.cloud"] = MagicMock()
sys.modules["google.cloud.firestore_v1"] = _firestore_v1_stub
sys.modules["google.cloud.firestore_v1.base_query"] = _base_query_stub

# rembg / PIL
sys.modules["rembg"] = MagicMock()
_pil_stub = MagicMock()
sys.modules["PIL"] = _pil_stub
sys.modules["PIL.Image"] = _pil_stub.Image

from fastapi.testclient import TestClient  # noqa: E402
from main import app  # noqa: E402

client = TestClient(app, raise_server_exceptions=False)

VALID_AUTH = {"Authorization": "Bearer fake-valid-token"}


# ── /remove-bg/ ──────────────────────────────────────────────────────────────

class TestRemoveBg:
    def test_rejects_non_image(self):
        response = client.post(
            "/remove-bg/",
            files={"file": ("doc.pdf", b"data", "application/pdf")},
        )
        assert response.status_code == 400
        assert "image" in response.json()["detail"].lower()

    def test_requires_file_field(self):
        response = client.post("/remove-bg/")
        assert response.status_code == 422


# ── /process-item/ ───────────────────────────────────────────────────────────

class TestProcessItem:
    def test_rejects_non_image(self):
        response = client.post(
            "/process-item/",
            files={"file": ("data.txt", b"hello", "text/plain")},
        )
        assert response.status_code == 400
        assert "image" in response.json()["detail"].lower()

    def test_requires_file_field(self):
        response = client.post("/process-item/")
        assert response.status_code == 422


# ── /generate-outfit/ ────────────────────────────────────────────────────────

class TestGenerateOutfit:
    def test_missing_auth_returns_401(self):
        response = client.post("/generate-outfit/", json={
            "user_prompt": "casual day",
            "current_weather": "20°C, Clear",
            "hourly_forecast": "Sunny all day",
        })
        assert response.status_code == 401

    def test_invalid_token_returns_401(self):
        _firebase_stub.auth.verify_id_token.side_effect = Exception("Token expired")
        response = client.post(
            "/generate-outfit/",
            json={
                "user_prompt": "casual day",
                "current_weather": "20°C, Clear",
                "hourly_forecast": "Sunny all day",
            },
            headers={"Authorization": "Bearer expired-token"},
        )
        assert response.status_code == 401
        _firebase_stub.auth.verify_id_token.side_effect = None

    def test_missing_required_fields_returns_422(self):
        response = client.post(
            "/generate-outfit/",
            json={"user_prompt": "casual day"},
            headers=VALID_AUTH,
        )
        assert response.status_code == 422


# ── /generate-outfits/ (shopping — no auth) ──────────────────────────────────

class TestGenerateOutfits:
    def test_missing_body_returns_422(self):
        response = client.post("/generate-outfits/")
        assert response.status_code == 422

    def test_invalid_body_structure_returns_422(self):
        response = client.post("/generate-outfits/", json={"unexpected": "field"})
        assert response.status_code == 422


# ── /generate-packing/ ───────────────────────────────────────────────────────

class TestGeneratePacking:
    def test_missing_auth_returns_401(self):
        response = client.post("/generate-packing/", json={
            "destination": "Paris",
            "days": 5,
            "vibe": "Casual",
            "weather_forecast": "Mild",
        })
        assert response.status_code == 401

    def test_missing_required_fields_returns_422(self):
        response = client.post(
            "/generate-packing/",
            json={"destination": "Paris"},
            headers=VALID_AUTH,
        )
        assert response.status_code == 422


# ── /generate-trip-outfit/ ───────────────────────────────────────────────────

class TestGenerateTripOutfit:
    def test_missing_auth_returns_401(self):
        response = client.post("/generate-trip-outfit/", json={
            "destination": "Rome",
            "vibe": "Tourist",
            "weather_forecast": "Sunny",
            "suitcase_item_ids": ["id1"],
            "user_context": "Museum visit",
        })
        assert response.status_code == 401

    def test_missing_required_fields_returns_422(self):
        response = client.post(
            "/generate-trip-outfit/",
            json={"destination": "Rome"},
            headers=VALID_AUTH,
        )
        assert response.status_code == 422


# ── /weather/current ─────────────────────────────────────────────────────────

class TestWeatherCurrent:
    def test_missing_both_params_returns_422(self):
        response = client.get("/weather/current")
        assert response.status_code == 422

    def test_missing_lon_returns_422(self):
        response = client.get("/weather/current?lat=46.77")
        assert response.status_code == 422

    def test_missing_lat_returns_422(self):
        response = client.get("/weather/current?lon=23.59")
        assert response.status_code == 422


# ── /weather/trip-summary ────────────────────────────────────────────────────

class TestWeatherTripSummary:
    def test_missing_params_returns_422(self):
        response = client.get("/weather/trip-summary")
        assert response.status_code == 422

    def test_missing_dates_returns_422(self):
        response = client.get("/weather/trip-summary?destination=Paris")
        assert response.status_code == 422
