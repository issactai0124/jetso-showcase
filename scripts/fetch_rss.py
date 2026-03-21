import os
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
import dateutil.parser
import time

# 強製控制台輸出為 UTF-8 並開啟 line_buffering 確保即時顯示
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

genai.configure(api_key=GEMINI_API_KEY)
# 使用穩定的模型名稱
model_lists_str = os.environ.get("GEMINI_MODEL_LIST", "gemini-3-flash-preview,gemini-2.5-flash,gemini-2.5-flash-lite")
model_lists = [m.strip() for m in model_lists_str.split(",") if m.strip()]

# 取得上次處理時間
last_processed_file = "assets/data/last_rss_time.txt"
processed_ids_file = "assets/data/processed_rss_ids.txt"
last_processed_time = None
processed_ids = set()

def ensure_aware(dt):
    if dt is None:
        return None
    if dt.tzinfo is None:
        # 如果是 naive，預設補上 UTC
        return dt.replace(tzinfo=timezone.utc)
    return dt

if os.path.exists(last_processed_file):
    with open(last_processed_file, "r") as f:
        ts_str = f.read().strip()
        if ts_str:
            try:
                last_processed_time = ensure_aware(dateutil.parser.parse(ts_str))
            except:
                pass

if os.path.exists(processed_ids_file):
    with open(processed_ids_file, "r") as f:
        processed_ids = set(line.strip() for line in f if line.strip())

print(f"Last processed time: {last_processed_time}")
print(f"Loaded {len(processed_ids)} processed IDs.")

# 下載並解析 RSS (Atom)
RSS_URL = "https://feeds2.feedburner.com/jetsoclub"

req = urllib.request.Request(RSS_URL, headers={'User-Agent': 'Mozilla/5.0'})
try:
    xml_data = urllib.request.urlopen(req).read()
except Exception as e:
    print(f"Failed to fetch RSS: {e}")
    exit(1)

root = ET.fromstring(xml_data)
ns = {'atom': 'http://www.w3.org/2005/Atom'}

new_entries = []
latest_time_in_feed = last_processed_time

for entry in root.findall('atom:entry', ns):
    entry_id = entry.find('atom:id', ns).text
    published_node = entry.find('atom:published', ns)
    if published_node is None:
        continue
        
    entry_time = ensure_aware(dateutil.parser.parse(published_node.text))
    
    # 找尋這批 feed 中最新的時間
    if latest_time_in_feed is None or entry_time > latest_time_in_feed:
        latest_time_in_feed = entry_time
        
    # 過濾條件：
    # 1. 時間必須大於或等於上次處理的最新時間
    # 2. 如果時間等於上次處理時間，則必須不在已處理 ID 列表中
    if last_processed_time is not None:
        if entry_time < last_processed_time:
            continue
        if entry_time == last_processed_time and entry_id in processed_ids:
            continue
    
    # 額外保險：即便時間大於 last_processed_time，如果 ID 已經處理過也跳過
    if entry_id in processed_ids:
        continue
        
    title_node = entry.find('atom:title', ns)
    title = title_node.text if title_node is not None else "No Title"
    summary = entry.find('atom:summary', ns)
    summary_text = summary.text if summary is not None else ""
    new_entries.append({"id": entry_id, "title": title, "content": summary_text, "time": entry_time})


# 照時間排序（舊的優先處理，確保順序正確）
new_entries.sort(key=lambda x: x["time"])

if not new_entries:
    print("No new entries to process.")
    exit(0)

print(f"Found {len(new_entries)} new entries. Sending to Gemini for analysis...\n")

# Gemini 分析邏輯
system_instruction = """
你是一個嚴格的優惠分析員。你的任務是過濾香港的優惠貼文。
針對每一項貼文，請盡量填寫以下資訊：
shop=商店名
payment=支付方法/會員/身份(如長者)
min_spend=最低消費額
rate=折扣(百分比)
amt=折扣額(數字)
start_date=優惠開始日期 (格式 yyyy-MM-dd)
end_date=優惠完結日期 (格式 yyyy-MM-dd)
applicable_days_of_week=每周星期幾適用 (例如: 1,2,3)
applicable_days_of_month=每月適用日子 (例如: 2,20)

請以雙引號包圍所有欄位的字串，例如 shop="AEON"，但數字不需要包圍

然後以下列原因分析是否過濾：
【必須接受的條件】
1. 該優惠必須涵蓋以下商店類型：超市、便利店、食品店、餅店、健康美容店。
2. 該優惠「必須」是「會員專屬優惠」或者是要求「特定支付方式/特定信用卡」的優惠。

【必須拒絕的條件】
1. 完全排除以下商店類型的優惠：餐廳、服裝店、家具店、珠寶店、小店、百貨公司、機票、電器等。
2. 完全排除「任何人」都可以享受的普通特價、減價宣傳、週末優惠、新品推廣等。即使是符合的商店，如果沒有門檻，也必須拒絕。

result=你的分析結果(1代表接受符合所有嚴格條件，0代表拒絕，2代表不肯定，-1代表有錯誤)
text=文字說明
如分析結果是接受，請以文字說明優惠內容，例如「每月2、20日以AEON信用卡簽帳可享5%優惠」
否則，請以文字說明拒絕原因，例如「餐廳」

輸出格式要求：你必須「只」輸出一行格式化的字串，各欄位以 "|" 分隔。不包含欄位不要輸出。不要輸出任何 Markdown 或說明文字。
範例輸出 1 (接受)：
shop="AEON"|payment="AEON信用卡"|rate=0.05|start_date="2026-03-21"|end_date="2026-03-28"|text="每月2、20日以AEON信用卡簽帳可享5%優惠"|result=1

範例輸出 2 (拒絕：純特價或不符商店)：
shop="譚仔雲南米線"|text="餐廳"|result=0
"""

os.makedirs("assets/data", exist_ok=True)
toaddlist_path = "assets/data/toaddlist.txt"

current_model_idx = 0
with open(toaddlist_path, "a", encoding="utf-8") as f:
    for i, entry in enumerate(new_entries, 1):
        prompt = f"請分析以下貼文：\n標題：{entry['title']}\n內文片段：{entry['content']}"
        print(f"--- 處理第 {i}/{len(new_entries)} 筆 ---")
        print(f"標題: {entry['title']}")
        
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
                f.write(f'title="{entry["title"]}"|{clean_result}\n')
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


# 所有處理完成後，更新 last_processed_time
if latest_time_in_feed:
    with open(last_processed_file, "w") as f:
        f.write(latest_time_in_feed.isoformat())
    print(f"Updated last processed time to: {latest_time_in_feed.isoformat()}")

# 儲存最近處理過的 ID (保留最後 500 個)
all_ids = list(processed_ids)
for entry in new_entries:
    if entry["id"] not in all_ids:
        all_ids.append(entry["id"])
        
with open(processed_ids_file, "w") as f:
    # 只保留最後 100 個 unique ID
    for eid in all_ids[-100:]:
        f.write(f"{eid}\n")
print(f"Updated processed IDs (total: {len(all_ids[-100:])})")

print("分析完成。")

