import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ EROARE: Nu am găsit GEMINI_API_KEY în fișierul .env!")
else:
    try:
        client = genai.Client(api_key=api_key)
        print("\n🔍 Se listează TOATE modelele disponibile pentru cheia ta:\n")
        
        # Listăm tot ce returnează Google, fără filtre
        for model in client.models.list():
            print(f"- Nume model: {model.name}")
            
    except Exception as e:
        print(f"❌ Eroare: {str(e)}")