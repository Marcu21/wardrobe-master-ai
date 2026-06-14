# ✨ Wardrobe Master AI

Your personal AI-powered wardrobe assistant. Wardrobe Master AI helps you organize your clothes, build outfits, plan trips, manage laundry, and get personalized styling advice — all in one app. ✨

---

## 🤔 What it does

Wardrobe Master AI combines a Flutter mobile app with a Python backend powered by Google Gemini. Take a photo of any clothing item and the AI instantly analyzes it, fills in all the details, and adds it to your digital wardrobe. From there, you can mix and match outfits, chat with an AI stylist, pack for trips, and track how sustainably you're using your wardrobe.

---

## 🚀 Features

### 👔 Wardrobe Gallery
Browse your entire wardrobe in a filterable grid with category and sub-category chips. Tap any item to see its full details, or hit the **+** button to add something new.

### 🗂️ Multiple Wardrobes
Perfect if you split your time between cities or keep clothes in different places. Create as many named wardrobes as you need (e.g. "London", "Paris", "Beach House") and switch between them with the wardrobe selector in the app bar. When you switch, the entire app updates — Gallery, Laundry, AI Stylist, and Smart Packing all filter to the active wardrobe. You can also view all wardrobes together at any time. Wardrobes can be renamed or deleted whenever you need; deleting one moves its clothes to "All Wardrobes" rather than removing them.

### 🤖 Smart Clothing Analysis
When adding a new item, just take a photo (or upload one from your gallery) and optionally scan its care tag. The AI analyzes the image and automatically fills in:
- 📋 **Basic info** — category, sub-category, colors, material, brand
- 🎨 **Styling info** — occasions, seasonality, style vibe
- 🫧 **Laundry info** — washing instructions, care requirements
- 🌱 **Sustainability info** — estimated lifespan, eco notes
- 📊 **Usage stats** — how often you wear it, last worn date

The background is automatically removed from clothing photos for a clean look. 🪄

### ✏️ Clothing Detail
View and edit every detail of each item across five organized sections. Everything is editable after the initial AI scan.

### 📖 Lookbook (Outfits)
Save your favorite outfit combinations and browse them in a grid. Tap any outfit to see its full details and the items it's made of.

### 💬 AI Stylist Chat
Chat with your personal AI stylist. Describe what you need — a look for a job interview, a date night, a beach day — and get outfit suggestions built from your actual wardrobe. The AI also takes the **current weather** into account automatically. Each suggestion shows a visual card with the items and you can preview any outfit in full screen.

You can give **thumbs up or thumbs down** on any suggestion. A dislike opens a reason picker (style mismatch, weather mismatch, or context mismatch) — this feedback is saved and the AI uses it in future suggestions to avoid repeating combinations you didn't like and favour ones you did. 🧠

The AI can be set to **prioritize neglected items** (clothes you haven't worn in a while) from Settings. ♻️

### 🪞 Virtual Dressing Room
An interactive outfit builder where you layer clothing items one by one. Scroll through your wardrobe in category rows, toggle layers on and off, and see the full look come together. Can be opened with pre-selected items or start fresh.

### 🛍️ Shopping Assistant — "Should I Buy This?"
Take or upload a photo of a clothing item you're considering buying. The AI analyzes it and checks how well it fits with your existing wardrobe, giving you:
- 🎯 A **match score** showing how compatible it is with what you already own
- ✅ **Why it works** — the things that make it a good addition
- ⚠️ **Keep in mind** — potential clashes or gaps to watch out for
- 👀 **Generated outfits** showing exactly how you'd wear it with items you already have

At the end you can either **Buy & Add to Wardrobe** (jumping straight into the add flow with the item pre-analyzed) or **Discard** if it's not the right fit. 🗑️

### 📅 Calendar
Track what you wore and when. Browse by date and see outfit history with a swipeable outfit carousel for each day.

### 🧺 Laundry Manager
A smart laundry tracking system built right into the app:
- 🧺 Add items to a **virtual laundry basket** from your wardrobe grid
- 🔍 Filter by category and sub-category
- 🚨 Get **animated care alerts** when items in your basket can't safely be washed together
- ✂️ Use **Auto-Split Load** to break the wash into safe groups by color or fabric
- 💨 Tap **"Washing done?"** to see drying and ironing tips for every item in the basket
- 🟢 A **status banner** shows whether the current basket is safe, has warnings, or has a critical issue

### 🌱 Sustainability Dashboard
See how well you're actually using your wardrobe:
- 📈 **Wear-rate stats** — how often each item gets used
- 😴 **Neglected items** — clothes that haven't been worn in a long time
- 💰 **Investment tracking** — cost-per-wear breakdown

### 🧳 Smart Packing (Trips)
Plan what to pack for any trip with AI help:
1. 🌍 Enter your **destination** — with city autocomplete as you type
2. 📆 Pick your **travel period** using the date range picker
3. ✨ Choose a **trip vibe** (City Break, Business, Event, etc.)
4. 🧳 Select your **luggage size**
5. 📝 Optionally describe your **itinerary** (e.g. "visiting museums, hiking on Tuesday, fancy dinner") so the AI can tailor the packing list to your actual plans
6. 🤖 The AI picks the best items from your wardrobe and builds a complete capsule wardrobe for the trip
7. 👀 View your trip in two tabs:
   - 🧳 **Suitcase** — all packed items, with a "Stylist's Secret" note explaining the AI's reasoning. Tap **Edit** to add or remove items, then hit **Sync & Re-style** to regenerate outfits based on your updated suitcase
   - 👗 **Daily Outfits** — pre-planned looks built from your suitcase. Tap the edit icon on any outfit to **tweak it** with a custom instruction (e.g. "make it more formal"), or use the **"Add another outfit"** field at the bottom to generate a brand new outfit for a specific occasion
8. 💾 All trips are saved so you can revisit them anytime from **My Trips**

### 🌤️ Live Weather on Home Screen
The home screen shows current weather conditions so you can dress accordingly before you even open the stylist.

### ⚙️ Settings
- 👤 Edit your **display name**
- 🔒 **Change your password** (for email accounts)
- 🔑 Google Sign-In users have password managed by Google
- ♻️ Toggle **"Prioritize neglected items"** for AI Stylist suggestions
- 🗑️ **Delete account** with full data wipe

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| 📱 Mobile App | Flutter (iOS & Android) |
| ⚙️ Backend API | Python · FastAPI |
| 🤖 AI | Google Gemini |
| 🗄️ Database | Firebase Firestore |
| 🔐 Authentication | Firebase Auth (Email/Password + Google Sign-In) |
| 🖼️ Image Processing | rembg (background removal) |

---

## 📁 Project Structure

```
wardrobe-master-ai/
├── mobile_app/          # Flutter app
│   └── lib/
│       ├── screens/     # All app screens and their view models
│       ├── models/      # Data models (ClothingItem, Outfit, Trip, …)
│       ├── services/    # Firebase, API, and state services
│       ├── widgets/     # Shared UI components
│       ├── navigation/  # Route definitions
│       └── theme/       # Colors and styling
└── backend/             # FastAPI server
    ├── routers/         # API endpoints (clothing, stylist, shopping, trips, weather)
    ├── core/            # Firebase + Gemini initialization
    ├── models/          # Request/response schemas
    └── utils/           # Gemini response parsing helpers
```

---

## 🏁 Getting Started

### 🐍 Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

You'll need a `.env` file (or environment variables) with:
- `GEMINI_API_KEY` — your Google Gemini API key 🤖
- Firebase service account credentials for Firestore access 🔥

### 📱 Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

Make sure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place for Firebase to work. 🔥

> First time? The login screen also lets you **create a new account** with your name, email, and password — or jump straight in with Google Sign-In. 🚀

---

## 🔌 Backend API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/remove-bg/` | 🖼️ Remove background from a clothing photo |
| POST | `/process-item/` | 🤖 AI analysis of a clothing item image |
| POST | `/generate-outfit/` | 💬 AI stylist — generate an outfit from the user's wardrobe |
| POST | `/generate-outfits/` | 🛍️ Shopping assistant — score a scanned item against the user's wardrobe |
| POST | `/generate-packing/` | 🧳 AI-powered trip capsule wardrobe from wardrobe |
| POST | `/generate-trip-outfit/` | 👗 Generate or tweak a specific outfit for a trip occasion |
| GET | `/weather/current` | 🌤️ Current weather data by coordinates |
| GET | `/weather/trip-summary` | 📆 Weather forecast summary for a trip date range |
| GET | `/weather/city-suggestions` | 🔍 City autocomplete suggestions |
