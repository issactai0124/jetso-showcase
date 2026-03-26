import os
import sys
sys.path.append(os.path.dirname(__file__))
import asyncio
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from mcp_server import mcp
import bot_logic
import telegram_bot
from telegram import Update
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import json
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup: Initialize Telegram bot
    if telegram_bot.application:
        await telegram_bot.application.initialize()
        print("Telegram bot initialized")
    
    yield
    
    # Shutdown: Stop Telegram bot
    if telegram_bot.application:
        await telegram_bot.application.shutdown()
        print("Telegram bot shut down")

app = FastAPI(title="Jetso Bot Unified Server", lifespan=lifespan)

# Enable CORS for the web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "assets", "data")
WEB_DIR = os.path.join(BASE_DIR, "web")

# Mount MCP SSE app at /mcp
app.mount("/mcp", mcp.sse_app())

@app.get("/api/health")
async def health():
    return {"status": "online", "message": "Jetso Bot Unified Server is running"}

# Admin Endpoints
@app.get("/admin")
async def serve_admin():
    return FileResponse(os.path.join(WEB_DIR, "admin.html"))

@app.get("/api/toaddlist")
async def get_toaddlist():
    txt_path = os.path.join(DATA_DIR, "toaddlist.txt")
    content = ""
    if os.path.exists(txt_path):
        with open(txt_path, "r", encoding="utf-8") as f:
            content = f.read()
    return {"text": content}

@app.get("/api/shops")
async def get_shops_api():
    from mcp_server import load_json
    return load_json("shops.json")

@app.get("/api/payments")
async def get_payments_api():
    from mcp_server import load_json
    return load_json("payment_methods.json")

@app.post("/api/save")
async def save_data(request: Request):
    data = await request.json()
    store_discounts = data.get("discounts", [])
    product_discounts = data.get("discounts_product", [])
    
    def append_to_file(filename, new_items):
        if not new_items: return
        path = os.path.join(DATA_DIR, filename)
        existing = []
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                try: existing = json.load(f)
                except: pass
        existing.extend(new_items)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(existing, f, ensure_ascii=False, indent=4)

    append_to_file("discounts.json", store_discounts)
    append_to_file("discounts_product.json", product_discounts)
    
    # Clear toaddlist.txt
    with open(os.path.join(DATA_DIR, "toaddlist.txt"), "w", encoding="utf-8") as f:
        f.write("")
    
    return {"status": "ok"}

@app.post("/api/chat")
async def chat_endpoint(request: Request):
    """Endpoint for the simple web chatbot interface."""
    data = await request.json()
    message = data.get("message")
    if not message:
        return {"error": "No message provided"}
    
    response = await bot_logic.process_query(message)
    return {"response": response}

@app.post("/telegram")
async def telegram_webhook(request: Request):
    """Endpoint for Telegram Webhook."""
    if not telegram_bot.application:
        return {"error": "Telegram bot not initialized"}
    
    try:
        data = await request.json()
        update = Update.de_json(data, telegram_bot.application.bot)
        await telegram_bot.application.process_update(update)
        return {"status": "ok"}
    except Exception as e:
        print(f"Error processing Telegram update: {e}")
        return {"status": "error", "message": str(e)}

# Serve static files from /web for index.html, chat.html, etc.
app.mount("/", StaticFiles(directory=WEB_DIR, html=True), name="web")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
