# Wardrobe Master AI 👗🤖

**An AI-powered mobile app for wardrobe management, outfit recommendations, smarter shopping decisions and clothing care.**

Wardrobe Master AI is a smart mobile app that helps users make better use of their wardrobe, discover new outfit combinations, make smarter shopping decisions and take better care of their clothes.

Instead of being just a digital closet, the app acts like a personal wardrobe assistant: it helps users organize what they own, get outfit suggestions based on weather and context, track what they wear, understand if a new item is worth buying and avoid damaging clothes during washing.

---

## ✨ Why I built it

A lot of people have the same problem: a full wardrobe, but “nothing to wear”.

Clothes get forgotten, outfit choices become repetitive, shopping decisions are often impulsive and care labels are confusing enough that many items end up damaged after washing.

Wardrobe Master AI was built to make wardrobe management smarter, more practical and more sustainable.

---

## 🧩 Main features

### 📸 Smart wardrobe digitization
Users can add clothing items by uploading photos. The app processes the image and helps turn each item into part of a structured digital wardrobe.

What this includes:
- background removal for clothing images
- automatic extraction of useful metadata
- category and subcategory detection
- color, material and pattern identification
- storing each item in a searchable wardrobe

This makes the wardrobe cleaner, easier to manage and much more useful for recommendations later.

---

### 👗 AI Stylist
The app can generate outfit suggestions using the items that already exist in the user’s wardrobe.

It takes into account:
- the user’s clothing items
- weather conditions
- context or occasion
- clothing compatibility

The result is not just a set of items, but also an explanation of why the outfit works.

---

### 🌦️ Weather-adaptive outfit recommendations
Wardrobe Master AI integrates weather data so outfit suggestions are more practical and realistic.

For example, the app can avoid recommending outfits that do not fit the current temperature or weather conditions and instead propose combinations that are both stylish and wearable.

---

### 🪞 Virtual Dressing Room
Users can manually build outfits from the clothes they already own.

This feature allows them to:
- combine clothing items freely
- experiment with different looks
- create outfits without physically trying everything on
- save favorite combinations for later

It works like a digital space for outfit planning.

---

### 💾 Saved outfits
Both manually created outfits and AI-generated outfits can be saved inside the app.

This helps users keep their favorite combinations in one place and reuse them later instead of rebuilding them every time.

---

### 🛍️ Should I Buy It?
This is a shopping assistant built to help users decide whether a new clothing item is actually worth buying.

Instead of making a decision in isolation, the app evaluates the item in relation to the user’s existing wardrobe.

It provides:
- a **match score**
- an explanation of **why the item fits or does not fit**
- useful things to **keep in mind before buying**
- **3 possible outfit ideas** that could be created using the new item

This feature supports smarter shopping decisions and helps reduce redundant purchases.

---

### 📅 Style Calendar
Users can mark an outfit as worn and the app adds it to a calendar view.

This makes it easier to:
- track previously worn outfits
- avoid repeating the same looks too often
- understand wardrobe usage over time
- keep a visual history of styling choices

---

### 🌱 Sustainability Tracker
The app also focuses on more conscious wardrobe usage.

It helps users better understand how they use their clothes by showing insights such as:
- **cost per wear**
- rarely worn items
- items that may deserve more use
- better long-term wardrobe value

This feature encourages users to make better use of what they already own instead of constantly buying new pieces.

---

### 🧺 Laundry Lens
Wardrobe Master AI also includes support for clothing care.

Users can scan clothing labels and get help understanding care instructions more easily.

This module includes:
- care label scanning
- decoding clothing care instructions
- storing care details digitally for each item
- attaching washing information to wardrobe items

The goal is to reduce mistakes caused by unclear care symbols.

---

### 🚨 Smart Laundry Basket
Users can place multiple clothing items into a virtual laundry basket and the app checks whether they are safe to wash together.

It can detect problems such as:
- incompatible washing temperatures
- risky color combinations
- material-related incompatibilities

Example warnings:
- “Do not wash wool at 60°C”
- “This red item may stain white clothes”

This makes laundry decisions safer and more practical.

---

## 🛠️ Tech stack

### 📱 Mobile
- Flutter
- Dart

### ⚙️ Backend
- FastAPI
- Python

### ☁️ Database & storage
- Firebase Firestore
- Firebase Storage

### 🔗 External integrations
- Weather API
- LLM-based AI flows
- image processing pipeline

---

## 🔄 How it works

### 👕 Adding a clothing item
1. The user uploads a photo of a clothing item
2. The app processes the image
3. Metadata is extracted
4. The item is stored in the digital wardrobe

### 🤖 Getting an outfit recommendation
1. The user opens the AI stylist
2. The app uses wardrobe data and weather context
3. A suitable outfit is generated
4. The selected items and explanation are shown

### 🛒 Checking if a new item is worth buying
1. The user provides a potential new clothing item
2. The app compares it against the existing wardrobe
3. It returns a score, explanation and outfit suggestions

### 🫧 Getting laundry help
1. The user scans a clothing label
2. Care instructions are extracted
3. Clothing items can be added to a laundry basket
4. The app checks compatibility and warns about risks

---

## 🎯 Project goals

This project was developed as a bachelor thesis application and combines:
- mobile development
- software engineering
- practical AI integration
- recommendation logic
- sustainability-focused design

The goal was not just to create a digital wardrobe, but to build an assistant that helps users make better everyday decisions related to clothing.

---

## 💡 Final note

Wardrobe Master AI is built around a simple idea: clothes should be easier to organize, easier to wear, easier to care for and easier to understand.

The app tries to turn wardrobe management from a frustrating daily task into a smarter and more helpful experience.