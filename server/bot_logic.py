import sys
import os
sys.path.append(os.path.dirname(__file__))
import json
import asyncio
from google import genai
from google.genai import types
from google.genai import errors

# Load environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
model_lists_str = os.environ.get("GEMINI_MODEL_LIST", "gemini-3-flash-preview,gemini-2.5-flash,gemini-2.5-flash-lite")
model_lists = [m.strip() for m in model_lists_str.split(",") if m.strip()]

# Initialize Gemini Client
client = genai.Client(api_key=GEMINI_API_KEY)

def create_gemini_tools_from_mcp(mcp_tools):
    """Dynamically converts MCP tools to Gemini's Tool format."""
    # This is a bit manual because we need to define Schema for Gemini.
    # In a fully dynamic version, we could use the MCP tool documentation.
    function_declarations = []
    
    # We define them explicitly here to match mcp_server.py exactly.
    # search_discounts
    fd_search = types.FunctionDeclaration(
        name="search_discounts",
        description="Search for discounts by an exact shop_id, payment_id, or by a keyword. Use get_shops() or get_payment_methods() to find the correct IDs first if you are unsure.",
        parameters=types.Schema(
            type=types.Type.OBJECT,
            properties={
                "shop_id": types.Schema(type=types.Type.STRING, description="Exact shop ID (e.g. 7eleven, watsons)"),
                "payment_id": types.Schema(type=types.Type.STRING, description="Exact payment method ID (e.g. aplus_rewards, enjoy_card, payme). Use get_payment_methods() to find the correct ID."),
                "keyword": types.Schema(type=types.Type.STRING, description="Keyword to search in discount title")
            }
        )
    )
    function_declarations.append(fd_search)

    # get_shops
    fd_shops = types.FunctionDeclaration(
        name="get_shops",
        description="Get the full list of shops supported by Jetso Showcase. Use this to lookup an exact shop_id.",
        parameters=types.Schema(type=types.Type.OBJECT, properties={})
    )
    function_declarations.append(fd_shops)

    # get_payment_methods
    fd_payments = types.FunctionDeclaration(
        name="get_payment_methods",
        description="Get the full list of supported payment methods (e.g. credit cards, e-wallets) and their IDs.",
        parameters=types.Schema(type=types.Type.OBJECT, properties={})
    )
    function_declarations.append(fd_payments)

    return [types.Tool(function_declarations=function_declarations)]

async def process_query(user_text: str, mcp_client=None) -> str:
    """
    Agentic loop with Gemini.
    If mcp_client is provided (as a ClientSession), it uses it.
    Otherwise, it uses direct imports from mcp_server.
    """
    system_prompt = (
        f"You are Jetso Bot, a smart assistant helping users find discounts in Hong Kong.\n"
        "Always use the provided tools to search the discount database. "
        "If the user doesn't provide an exact shop_id, use get_shops() to find it first. "
        "If the user asks about a payment method (e.g. credit card, Alipay, Payme), use get_payment_methods() to find the correct payment_id and then use it in search_discounts(). "
        "Reply to the user in traditional Chinese (zh-HK) in a friendly and helpful tone. "
        "Use newlines (\\n) and bullet points to separate different discounts and sections clearly. "
        "Example format:\n"
        "商店名稱：\n"
        "* 配合優惠工具/付款方式 (如有)\n"
        "* 優惠項目內容1\n"
        "* 優惠項目內容2\n\n"
        "You should give discounts that will end soon first. Otherwise gives the discounts with the most discount amount first."
    )
    
    gemini_tools = create_gemini_tools_from_mcp(None)

    resource_exhausted = False
    for model_name in model_lists:
        try:
            chat = client.chats.create(
                model=model_name,
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.3,
                    tools=gemini_tools
                )
            )
            
            response = chat.send_message(user_text)
            
            while response.function_calls:
                for fn_call in response.function_calls:
                    args_dict = dict(fn_call.args) if fn_call.args else {}
                    
                    if mcp_client:
                        # Remote call via MCP protocol
                        tool_result = await mcp_client.call_tool(fn_call.name, arguments=args_dict)
                        result_text = tool_result.content[0].text if tool_result.content else "{}"
                    else:
                        # Direct call
                        import mcp_server
                        if hasattr(mcp_server, fn_call.name):
                            tool_func = getattr(mcp_server, fn_call.name)
                            if asyncio.iscoroutinefunction(tool_func):
                                result_text = await tool_func(**args_dict)
                            else:
                                result_text = tool_func(**args_dict)
                        else:
                            result_text = f"{{'error': 'tool {fn_call.name} not found'}}"
                    
                    response = chat.send_message(
                        types.Part.from_function_response(
                            name=fn_call.name,
                            response={"result": result_text}
                        )
                    )
            
            print(f"DEBUG - Gemini ({model_name}) Response: {response.text}")
            return response.text
        except errors.APIError as e:
            if e.code == 429:
                resource_exhausted = True
                print(f"⚠️ Model {model_name} is exhausted (429).")
            else:
                print(f"❌ API Error with model {model_name}: {e}")
                continue
        except Exception as e:
            print(f"❌ Error with model {model_name}: {str(e)}")
            continue
            
    if resource_exhausted:
        return "抱歉，目前 AI 額度已用完，請稍後再試。"
    return "抱歉，我現在無法處理您的請求。"
