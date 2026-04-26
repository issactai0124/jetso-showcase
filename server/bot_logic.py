import sys
import os
sys.path.append(os.path.dirname(__file__))
import json
import asyncio
from google import genai
from google.genai import types
from google.genai import errors

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
model_lists_str = os.environ.get("GEMINI_MODEL_LIST", "gemini-3-flash-preview,gemini-2.5-flash,gemini-2.5-flash-lite")
model_lists = [m.strip() for m in model_lists_str.split(",") if m.strip()]

# Initialize Gemini Client
client = genai.Client(api_key=GEMINI_API_KEY)

async def process_query(user_text: str) -> str:
    """
    Agentic loop with Gemini using pure Python Skills.
    """
    system_prompt = (
        "You are Jetso Bot, a smart assistant helping users find discounts in Hong Kong.\n"
        "Always use the provided tools to search the discount database. "
        "If the user doesn't provide an exact shop_id, use get_shops() to find it first or use a shop_category instead. "
        "If the user asks about a payment method (e.g. credit card, Alipay, Payme), use get_payment_methods() to find the correct payment_id and then use it in search_discounts(). "
        "Reply to the user in traditional Chinese (zh-HK) in a friendly and helpful tone. "
        "Use newlines (\\n) and bullet points to separate different discounts and sections clearly. "
        "Example format:\n"
        "商店名稱：\n"
        "* 優惠項目1（配合優惠工具/付款方式）\n"
        "* 優惠項目2（配合優惠工具/付款方式）\n"
        "* 優惠項目3（配合優惠工具/付款方式）\n\n"
        "If a tool returns `fallback_discounts` with a `fallback_message`, it means there are no exact matches for the user's criteria (e.g., date, payment method). In this case, you MUST inform the user that there are no discounts for their specific criteria, but list the fallback discounts provided. For example: '[商店名稱]在[特定條件]沒有任何優惠，但有以下優惠：' followed by the fallback discounts.\n"
        "You should give discounts that will end soon first. Otherwise gives the discounts with the most discount amount first."
    )
    
    import jetso_skills
    gemini_tools = [jetso_skills.search_discounts, jetso_skills.get_shops, jetso_skills.get_payment_methods]

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
                    
                    if hasattr(jetso_skills, fn_call.name):
                        tool_func = getattr(jetso_skills, fn_call.name)
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
