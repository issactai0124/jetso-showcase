import os
import json
import asyncio
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import bot_logic

# Load environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")

if not GEMINI_API_KEY or not TELEGRAM_BOT_TOKEN:
    print("Warning: Please set GEMINI_API_KEY and TELEGRAM_BOT_TOKEN")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle incoming telegram messages."""
    if not update.message or not update.message.text:
        return
        
    user_text = update.message.text
    chat_id = update.effective_chat.id
    
    # Send a thinking indicator
    await context.bot.send_chat_action(chat_id=chat_id, action="typing")
    
    try:
        import re
        reply = await bot_logic.process_query(user_text)
        # Convert Markdown bold ** to HTML bold <b>
        # We also need to escape <, > and & first 
        html_reply = reply.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        html_reply = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', html_reply)
        
        await update.message.reply_text(html_reply, parse_mode='HTML')
    except Exception as e:
        print(f"Error: {e}")
        await update.message.reply_text(f"抱歉，系統遇到了一點問題: {e}")

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("你好！我是 Jetso 優惠小助手。請輸入商店名稱或優惠關鍵字，例如：7-11 或 HSBC信用卡")

def create_application():
    """Initialize the Telegram application."""
    if not TELEGRAM_BOT_TOKEN:
        return None
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    return app

# The globally accessible application for app.py
application = create_application()

def main() -> None:
    """Start the bot in polling mode (local)."""
    if not application:
        print("Telegram application failed to initialize. Check TELEGRAM_BOT_TOKEN.")
        return
    print("Starting Telegram Bot (Polling)...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
