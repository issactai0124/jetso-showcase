import os
import sys
sys.path.append(os.path.dirname(__file__))
import json
import datetime
from mcp.server.fastmcp import FastMCP

# Initialize FastMCP server
mcp = FastMCP("JetsoShowcase", dependencies=["mcp"])

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "data")

def load_json(filename: str) -> list:
    path = os.path.join(DATA_DIR, filename)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def get_shops() -> str:
    """Get the full list of shops supported by Jetso Showcase. Use this to lookup an exact shop_id."""
    shops = load_json("shops.json")
    condensed = [{"id": s["id"], "name": s.get("name_zh", "")} for s in shops]
    return json.dumps(condensed, ensure_ascii=False)

def get_payment_methods() -> str:
    """Get the full list of supported payment methods (e.g. credit cards, e-wallets) and their IDs."""
    payments = load_json("payment_methods.json")
    condensed = [{"id": p["id"], "name": p.get("name_zh", "")} for p in payments]
    return json.dumps(condensed, ensure_ascii=False)

def search_discounts(shop_id: str = None, payment_id: str = None, keyword: str = None) -> str:
    """Search for discounts by an exact shop_id, payment_id, or by a keyword. 
    Use get_shops() or get_payment_methods() to find the correct IDs first if you are unsure.
    """
    discounts = load_json("discounts.json")
    product_discounts = load_json("discounts_product.json")
    
    # Get today's date in HK time formatted as YYYY-MM-DD
    today_str = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).strftime("%Y-%m-%d")
    
    all_discounts = discounts + product_discounts
    results = []
    
    for d in all_discounts:
        # Filter out expired discounts at the source
        end_date = d.get("end_date")
        if end_date and end_date < today_str:
            continue
            
        match = True
        if shop_id and shop_id not in d.get("shop_ids", []):
            match = False
        if payment_id and payment_id not in d.get("required_payment_ids", []):
            match = False
        if keyword:
            title = (d.get("title_zh", "") + " " + d.get("title_en", "")).lower()
            if keyword.lower() not in title:
                match = False
        if match:
            results.append(d)
            
    # Cap results to avoid blowing up context window
    return json.dumps(results[:30], ensure_ascii=False)

# Register tools with MCP
mcp.tool()(get_shops)
mcp.tool()(get_payment_methods)
mcp.tool()(search_discounts)

if __name__ == "__main__":
    # If run with --sse, use HTTP Server-Sent Events transport. Otherwise defaults to stdio transport.
    transport = "sse" if "--sse" in sys.argv else "stdio"
    port = int(os.environ.get("PORT", 8080))
    host = os.environ.get("HOST", "0.0.0.0")
    
    if transport == "sse":
        print(f"Starting MCP Server on SSE ({host}:{port})", file=sys.stderr)
        # Note: If SSE transport starts failing for you in the future because of host/port settings, FastMCP uses `run()` for stdio and `mcp.app` or similar for custom SSE servers.
        # But for stdio (which we use here), it just needs `mcp.run(transport="stdio")`.
        mcp.run(transport="sse")
    else:
        print("Starting MCP Server on stdio", file=sys.stderr)
        mcp.run(transport="stdio")
