import os
import sys
import urllib.request
import json
import time

# 強製控製台輸出為 UTF-8 並開啟 line_buffering 確保即時顯示
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', line_buffering=True)
else:
    # 確保非 Windows 環境也能即時輸出
    import sys
    sys.stdout.reconfigure(line_buffering=True)


# 忽略 deprecation warning
import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import google.generativeai as genai

# 配置 Gemini
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("Error: GEMINI_API_KEY is not set.")
    exit(1)
model_lists_str = os.environ.get("GEMINI_MODEL_LIST", "gemini-3-flash-preview,gemini-2.5-flash,gemini-2.5-flash-lite")
model_lists = [m.strip() for m in model_lists_str.split(",") if m.strip()]

genai.configure(api_key=GEMINI_API_KEY)

# 狀態管理：記錄已處理過的 RewardBuy ID
STATE_DIR = "assets/data"
os.makedirs(STATE_DIR, exist_ok=True)
PROCESSED_IDS_FILE = os.path.join(STATE_DIR, "processed_rewardbuy_ids.txt")

processed_ids = set()
if os.path.exists(PROCESSED_IDS_FILE):
    with open(PROCESSED_IDS_FILE, "r", encoding="utf-8") as f:
        processed_ids = set(line.strip() for line in f if line.strip())

# Fetch RewardBuy API for multiple categories
CATEGORIES = {
    "CP-08DE752E": "咖啡茶飲",
    "CP-CC5A443A": "麵包西餅",
    "CP-01E8C760": "生活百貨"
}

products = []
seen_ids_in_this_run = set()

for cat_id, cat_name in CATEGORIES.items():
    API_URL = f"https://rewardbuy.shop/proxy-appservice-api/app-service/json/market-products/rewardbuy_primary_marketplace?query_type=GENERIC&category={cat_id}&sort_id=hot&language=tc"
    req = urllib.request.Request(API_URL, headers={'User-Agent': 'Mozilla/5.0'})

    try:
        print(f"Fetching RewardBuy category: {cat_name} ({cat_id})")
        with urllib.request.urlopen(req) as response:
            resp_data = json.loads(response.read().decode('utf-8'))
            cat_products = resp_data.get("value", [])
            for p in cat_products:
                p_id = p.get("product_id")
                if p_id and p_id not in seen_ids_in_this_run:
                    products.append(p)
                    seen_ids_in_this_run.add(p_id)
    except Exception as e:
        print(f"Failed to fetch RewardBuy category {cat_name}: {e}")


def get_vouchers_detail(shop_id, product_id):
    detail_url = f"https://rewardbuy.shop/tc/products/{shop_id}/{product_id}"
    req = urllib.request.Request(detail_url, headers={'User-Agent': 'Mozilla/5.0'})
    result = {"dates": "未知", "stores": "未知"}
    try:
        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8')
            # 尋找換領日期
            import re
            date_match = re.search(r"換領日期\s*[:：]\s*(\d{2}/\d{2}/\d{4})\s*-\s*(\d{2}/\d{2}/\d{4})", html)
            if date_match:
                result["dates"] = f"{date_match.group(1)} - {date_match.group(2)}"
            
            # 尋找適用門店 (通常在 points 欄位中)
            # 範例: "points":"香港天仁茗茶全線分店可用..."
            store_match = re.search(r'"points"\s*:\s*"(.*?)"', html)
            if store_match:
                # 處理 unicode 轉義或簡單清理
                stores_text = store_match.group(1).replace('\\"', '"').replace('\\\\', '\\')
                result["stores"] = stores_text
    except:
        pass
    return result

new_entries = []
for p in products:
    p_id = p.get("product_id")
    shop_id = p.get("shop_id")
    if not p_id or p_id in processed_ids:
        continue
    
    name = p.get("product_name", "")
    brand = p.get("brand_name", "")
    orig = p.get("original_price", 0)
    price = p.get("unit_price", 0)
    
    # 抓取產品詳情
    print(f"Fetching details for: {name}...")
    details = get_vouchers_detail(shop_id, p_id)
    
    # 建立目前資訊供 Gemini 參考
    content = f"商戶: {brand} | 產品: {name} | 原價: {orig} | 現價: {price} | 換領日期: {details['dates']} | 適用門店: {details['stores']}"
    new_entries.append({
        "id": p_id,
        "title": f"好賞買: {name}",
        "content": content
    })



if not new_entries:
    print("No new RewardBuy items to process.")
    exit(0)

print(f"Found {len(new_entries)} new items. Analyzing with Gemini...\n")

# Gemini 分析邏輯 (與 RSS 腳本一致)
system_instruction = """
你是一個嚴格的優惠分析員。
現在你處理的是「好賞買」（英文為「RewardBuy」）的優惠資訊，請盡量填寫以下資訊：

shop=商店名
payment=支付方法/會員/身份(如長者)
min_spend=最低消費額 (指禮券的面值)
amt=折扣額(數字，即面值減購買價)
start_date=優惠開始日期 (格式 yyyy-MM-dd)
end_date=優惠完結日期 (格式 yyyy-MM-dd)
換領日期 : 21/11/2025 - 30/06/2026
start_date=2025-11-21
end_date=2026-06-30

請參考「適用門店」資訊來精確識別商店名稱 (shop)。
請以雙引號包圍所有欄位的字串，例如 shop="AEON"，但數字不需要包圍


然後以下列原因分析是否過濾：
【必須接受的條件】
1. 該優惠必須涵蓋以下商店類型：超市、便利店、食品店、餅店、健康美容店、咖啡店、茶飲店。
2. 對於 好賞買，通常是電子禮券或現金券，這屬於「特定支付方式」的一種。

【必須拒絕的條件】
完全排除以下商店類型：餐廳、服裝店、家具店、機票等。

result=你的分析結果(1代表接受，0代表拒絕，2代表不肯定)
text=文字說明
如分析結果是接受，請以文字說明優惠內容，例如「於好賞買以$48.7購買$50電子禮券」
否則，請以文字說明拒絕原因，例如「餐廳」

輸出格式要求：你必須「只」輸出一行格式化的字串，各欄位以 "|" 分隔。不包含欄位不要輸出。不要輸出任何 Markdown。
範例：
shop="city'super"|payment="好賞買"|min_spend=50|amt=1.3|text="於好賞買以$48.7購買$50電子禮券"|result=1
shop="皇玥"|payment="好賞買"|min_spend=138|text="於好賞買以$138購買原味蝴蝶酥精裝禮盒"|result=1
"""

TOADDLIST_PATH = os.path.join(STATE_DIR, "toaddlist.txt")


with open(TOADDLIST_PATH, "a", encoding="utf-8") as out_f, \
     open(PROCESSED_IDS_FILE, "a", encoding="utf-8") as id_f:
    
    current_model_idx = 0
    for i, entry in enumerate(new_entries, 1):
        print(f"--- 處理第 {i}/{len(new_entries)} 筆 ---")
        print(f"標題: {entry['title']}")
        
        prompt = f"請分析以下 RewardBuy 項目：\n{entry['content']}"
        success = False
        while current_model_idx < len(model_lists):
            model_name = model_lists[current_model_idx]
            print(f"嘗試使用模型: {model_name}")
            try:
                model = genai.GenerativeModel(model_name)
                response = model.generate_content(
                    f"{system_instruction}\n\n{prompt}",
                    generation_config=genai.types.GenerationConfig(temperature=0.1)
                )
                clean_result = response.text.strip().replace('\n', ' ')
                print(f"AI 輸出: {clean_result}\n")
                
                # 寫入待審核清單
                out_f.write(f'title="{entry["title"]}"|{clean_result}\n')
                # 標記為已處理
                id_f.write(f"{entry['id']}\n")
                
                success = True
                break
            except Exception as e:
                error_msg = str(e)
                print(f"❌ 模型 {model_name} 請求失敗: {error_msg}")
                current_model_idx += 1
                # 之後的項目會從新的 current_model_idx 開始嘗試
                continue
        
        if not success:
            print("🛑 所有模型均已嘗試且失敗，程序終止。")
            sys.exit(1)
        
        # 每一筆之間的基本間隔，避免過快觸發限制
        time.sleep(30)


print("RewardBuy 處理完成。")
