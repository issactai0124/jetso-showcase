# Jetso Discount Skills

This guide details the custom skills provided for querying and retrieving Jetso Showcase discount data. These skills are implemented as native Python functions in `server/jetso_skills.py` and can be provided directly to the LLM's `tools` parameter (e.g. using the Gemini SDK).

## Why Skills over MCP?
Unlike traditional Model Context Protocol (MCP) integrations which require a standalone RPC server and manual JSON schema declarations, this setup is lightweight:
1. Less Token Usage: the parameters are parsed directly from docstrings by the AI framework SDK.
2. Less Setup Overhead: no HTTP/stdio transmission or JSON-RPC format parsing is needed. 

## Supported Skills

The AI agent can utilize the following methods to fetch and filter JSON records efficiently:

### 1. `get_shops()`
- **Description:** Retrieves the full list of shops supported by Jetso Showcase.
- **Use Case:** Call this first to lookup exact `shop_id` or existing categories if the user asks for a specific brand name that you haven't seen before.

### 2. `get_payment_methods()`
- **Description:** Retrieves the full list of supported payment methods (e.g. credit cards, e-wallets, member cards) and their IDs.
- **Use Case:** Call this first if the user queries a discount by bank or payment method (e.g. HSBC, PayMe, Alipay) to figure out the exact `payment_id`.

### 3. `search_discounts(shop_id, shop_category, payment_id, keyword, valid_within_days)`
- **Description:** The core fetching tool. Search for discounts matching any of the specified parameters.
- **Use Case / Examples:** 
  - To find Wellcome discounts via HSBC credit card: `search_discounts(shop_id="wellcome", payment_id="hsbc_credit_card")`
  - To find supermarket discounts expiring in 5 days: `search_discounts(shop_category="超市便利", valid_within_days=5)`
  - To find all Häagen-Dazs deals: `search_discounts(shop_id="haagendazs")`
  
> Note: If filtering by `valid_within_days`, it will only return discounts that possess an explicit `end_date` within the next N days. Non-expiring (ongoing) discounts are omitted from this specific query to ensure high relevance for "expiring soon" requests.

## Implementation Integration
In Python, simply import these functions under `bot_logic.py` and pass them to the GenAI client:
```python
from jetso_skills import get_shops, get_payment_methods, search_discounts

tools = [get_shops, get_payment_methods, search_discounts]
chat = client.chats.create(
    model="gemini-3-flash",
    config=types.GenerateContentConfig(tools=tools)
)
```
