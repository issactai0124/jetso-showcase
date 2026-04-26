import os
import sys
import json
import datetime

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "data")

def load_json(filename: str) -> list:
    path = os.path.join(DATA_DIR, filename)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def get_shops() -> str:
    """Get the full list of shops supported by Jetso Showcase. Use this to lookup an exact shop_id or category."""
    shops = load_json("shops.json")
    condensed = [{"id": s["id"], "name": s.get("name_zh", ""), "category": s.get("category", "")} for s in shops]
    return json.dumps(condensed, ensure_ascii=False)

def get_payment_methods() -> str:
    """Get the full list of supported payment methods (e.g. credit cards, e-wallets) and their IDs."""
    payments = load_json("payment_methods.json")
    condensed = [{"id": p["id"], "name": p.get("name_zh", "")} for p in payments]
    return json.dumps(condensed, ensure_ascii=False)

def search_discounts(
    shop_id: str = "", 
    shop_category: str = "",
    payment_id: str = "", 
    keyword: str = "",
    valid_within_days: int = None
) -> str:
    """Search for discounts by exact shop_id, shop_category, payment_id, keyword, or expiry.
    Use get_shops() or get_payment_methods() to find the correct IDs/categories first if you are unsure.
    
    Args:
        shop_id: Exact shop ID (e.g. 7eleven, watsons, wellcome). Leave empty to not filter.
        shop_category: Category like 超市便利, 休閒飲品, 餅店甜品, 食品食材. Leave empty to not filter.
        payment_id: Exact payment method ID (e.g. hsbc_credit_card, enjoy_card, payme). Leave empty to not filter.
        keyword: Keyword to search in discount title. Leave empty to not filter.
        valid_within_days: Find discounts expiring strictly within this many days from today.
    """
    discounts = load_json("discounts.json")
    product_discounts = load_json("discounts_product.json")
    
    hk_tz = datetime.timezone(datetime.timedelta(hours=8))
    now = datetime.datetime.now(hk_tz)
    today_str = now.strftime("%Y-%m-%d")

    target_date_str = None
    if valid_within_days is not None and valid_within_days > 0:
        target_date = now + datetime.timedelta(days=valid_within_days)
        target_date_str = target_date.strftime("%Y-%m-%d")
    
    category_shop_ids = []
    if shop_category:
        shops = load_json("shops.json")
        for s in shops:
            cat = s.get("category", "") + " " + s.get("subcategory", "")
            if shop_category.lower() in cat.lower() or shop_category in cat:
                category_shop_ids.append(s["id"])
    
    all_discounts = discounts + product_discounts
    results = []
    
    for d in all_discounts:
        end_date = d.get("end_date")
        if end_date and end_date < today_str:
            continue
            
        match = True
        
        if shop_id and shop_id not in d.get("shop_ids", []):
            match = False
            
        if shop_category and match:
            in_category = any(sid in category_shop_ids for sid in d.get("shop_ids", []))
            if not in_category:
                match = False
                
        if payment_id and match:
            if payment_id not in d.get("required_payment_ids", []):
                match = False
                
        if keyword and match:
            title = (d.get("title_zh", "") + " " + d.get("title_en", "")).lower()
            if keyword.lower() not in title:
                match = False
                
        if valid_within_days is not None and valid_within_days > 0 and match:
            if not end_date:
                match = False # If it doesn't have an expiry date, it's not "expiring within N days"
            elif end_date > target_date_str:
                match = False
                
        if match:
            results.append(d)
            
    if not results and shop_id:
        fallback_results = []
        for d in all_discounts:
            end_date = d.get("end_date")
            if end_date and end_date < today_str:
                continue
            if shop_id in d.get("shop_ids", []):
                fallback_results.append(d)
                
        if fallback_results:
            return json.dumps({
                "exact_matches": [],
                "fallback_message": "No exact matches found for the specific criteria. However, here are other valid discounts for this shop.",
                "fallback_discounts": fallback_results[:5]
            }, ensure_ascii=False)
            
    return json.dumps(results[:30], ensure_ascii=False)
