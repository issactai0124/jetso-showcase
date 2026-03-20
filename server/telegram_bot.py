import os
import json
import asyncio
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from google import genai
from google.genai import types

# MCP standard client
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

# Load environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")

if not GEMINI_API_KEY or not TELEGRAM_BOT_TOKEN:
    print("Warning: Please set GEMINI_API_KEY and TELEGRAM_BOT_TOKEN")

# Initialize Gemini Client
client = genai.Client(api_key=GEMINI_API_KEY)
MODEL_ID = "gemini-2.5-flash"

async def function_to_mcp(mcp_session: ClientSession, tool_name: str, args: dict):
    """Executes a tool on the MCP server and returns the result."""
    result = await mcp_session.call_tool(tool_name, arguments=args)
    # The result contains content blocks
    return result.content[0].text if result.content else "No result."

def create_gemini_tools_from_mcp(mcp_tools):
    """Dynamically converts MCP tools to Gemini's FunctionDeclaration format."""
    gemini_tools = []
    function_declarations = []
    
    for tool in mcp_tools.tools:
        # Simplistic conversion: In a full app, map the full JSON schema here.
        # But since we know our specific tools, we can define them explicitly or map standard types.
        if tool.name == "search_discounts":
            fd = types.FunctionDeclaration(
                name="search_discounts",
                description=tool.description,
                parameters=types.Schema(
                    type=types.Type.OBJECT,
                    properties={
                        "shop_id": types.Schema(type=types.Type.STRING, description="Exact shop ID (e.g. 7eleven, watsons)"),
                        "keyword": types.Schema(type=types.Type.STRING, description="Keyword to search in discount title")
                    }
                )
            )
            function_declarations.append(fd)
        elif tool.name == "get_shops":
            fd = types.FunctionDeclaration(
                name="get_shops",
                description=tool.description,
                parameters=types.Schema(
                    type=types.Type.OBJECT,
                    properties={} 
                )
            )
            function_declarations.append(fd)
        elif tool.name == "get_payment_methods":
            fd = types.FunctionDeclaration(
                name="get_payment_methods",
                description=tool.description,
                parameters=types.Schema(
                    type=types.Type.OBJECT,
                    properties={} 
                )
            )
            function_declarations.append(fd)
            
    if function_declarations:
        gemini_tools.append(types.Tool(function_declarations=function_declarations))
    
    return gemini_tools


async def process_with_gemini_and_mcp(user_text: str) -> str:
    """Connects to MCP, fetches tools, and runs an agentic loop with Gemini."""
    
    # Configure the MCP stdio connection to our local MCP server
    server_params = StdioServerParameters(
        command="python",
        args=[os.path.join(os.path.dirname(__file__), "mcp_server.py")],
        env=None
    )
    
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Fetch tools exposed by our MCP server
            mcp_tools = await session.list_tools()
            gemini_tools = create_gemini_tools_from_mcp(mcp_tools)
            
            # Start Gemini session
            chat = client.chats.create(
                model=MODEL_ID,
                config=types.GenerateContentConfig(
                    system_instruction="You are Jetso Bot, a smart assistant helping users find discounts in Hong Kong. Always use the provided tools to search the discount database. If the user doesn't provide an exact shop_id, use get_shops() to find it first. Reply to the user in traditional Chinese (zh-HK) in a friendly and helpful tone.",
                    temperature=0.3,
                    tools=gemini_tools
                )
            )
            
            # Send initial user query
            response = chat.send_message(user_text)
            
            # Handle Function Calling Loop
            while response.function_calls:
                for fn_call in response.function_calls:
                    print(f"Gemini requested tool call: {fn_call.name} with args {fn_call.args}")
                    
                    # Convert arguments correctly
                    args_dict = dict(fn_call.args) if fn_call.args else {}
                    
                    # Call MCP Server!
                    tool_result = await session.call_tool(fn_call.name, arguments=args_dict)
                    result_text = tool_result.content[0].text if tool_result.content else "{}"
                    
                    # Send result back to Gemini
                    response = chat.send_message(
                        types.Part.from_function_response(
                            name=fn_call.name,
                            response={"result": result_text}
                        )
                    )
            
            return response.text

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle incoming telegram messages."""
    user_text = update.message.text
    chat_id = update.effective_chat.id
    
    # Send a thinking indicator
    await context.bot.send_chat_action(chat_id=chat_id, action="typing")
    
    try:
        reply = await process_with_gemini_and_mcp(user_text)
        await update.message.reply_text(reply)
    except Exception as e:
        print(f"Error: {e}")
        await update.message.reply_text(f"抱歉，系統遇到了一點問題: {e}")

async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("你好！我是 Jetso 優惠小助手。想找什麼商店或優惠呢？直接問我吧！")

def main() -> None:
    """Start the bot."""
    if not TELEGRAM_BOT_TOKEN:
        return
        
    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    application.add_handler(CommandHandler("start", start_command))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    print("Starting Telegram Bot...")
    
    # Render assigns a PORT and RENDER_EXTERNAL_URL
    port = int(os.environ.get("PORT", 8080))
    url = os.environ.get("RENDER_EXTERNAL_URL")
    
    if url:
        print(f"Running via Webhook on {url}:{port}")
        application.run_webhook(
            listen="0.0.0.0",
            port=port,
            webhook_url=url,
            secret_token=os.environ.get("WEBHOOK_SECRET", "jetso_secret")
        )
    else:
        print("Running via Polling (Local mode)...")
        application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
