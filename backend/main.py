from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import core.config  # noqa: F401 — ensures Firebase + Gemini init runs on startup
from routers import clothing, shopping, stylist, trips, weather

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(clothing.router)
app.include_router(shopping.router)
app.include_router(stylist.router)
app.include_router(trips.router)
app.include_router(weather.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
