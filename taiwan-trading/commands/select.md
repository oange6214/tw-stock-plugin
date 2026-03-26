---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[可選：指定股票代號清單，例如 '2330 2454 2382'；留空則自動從 TWSE 抓取篩選清單]"
---

分析 TWSE 最近一個交易日的收盤資料。直接分析歷史資料，**不判斷當前是否開盤、是否交易日、現在時間**。

> **前置條件**：工作目錄下需有 `.mcp.json` 掛載 `tw-stock-mcp`，否則 MCP 工具無法使用。
> 若尚未建立，請在工作目錄新增：
> ```json
> { "mcpServers": { "tw-stock-mcp": { "command": "tw-stock-mcp" } } }
> ```
> 並重啟 Claude Code。`tw-stock-mcp` 需先透過 `uv tool install` 安裝（詳見 `tw-stock-mcp/README.md`）。

## Phase 1：負乖離歷史比例篩選

### 若使用者提供股票代號

直接以逗號分隔字串傳入 Phase 2 掃描，跳過自動清單抓取。

### 若未提供股票代號（自動掃描全市場）

呼叫 MCP 工具 `get_deviation_scan`，**不傳入任何參數**（工具會自動抓取當日 TWSE 清單並過濾流動性）：

```
get_deviation_scan(stock_codes="")
```

工具內部會：
1. 從 `STOCK_DAY_ALL` 抓取當日清單（4 位數代號）
2. 抓取近 **6 個月** TWSE STOCK_DAY 資料（自動處理 SSL 憑證問題；5 個月資料量不足 91 筆門檻，全部股票會被 skip）
3. 計算 60MA（季線）乖離率，篩選：今日乖離 0~10%，近 30 日負乖離 ≥ 24 天
4. 回傳 `matched` 陣列

### 若提供了股票代號

呼叫 MCP 工具 `get_deviation_scan`，傳入代號清單：

```
get_deviation_scan(stock_codes="2330,2454,2382,...")
```

### 儲存篩選結果

工具回傳後，立即將 `matched` 清單儲存（**必須執行**）：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_HHMM_deviation.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 為最後交易日日期，HHMM 為當前執行時間（同一天可執行多次不互蓋）
- 若目錄不存在先建立

```markdown
# YYYY-MM-DD 負乖離歷史篩選結果

**掃描：** {total_scanned} 支 → 命中：{total_matched} 支

| 代號 | 名稱 | 收盤價 | 60MA | 今日乖離(%) | 近30日負乖離比例(%) |
|------|------|--------|------|------------|-------------------|
...
```

### 若 matched 為空 → **立即結束**

儲存篩選結果後，輸出：

> 本次掃描 {total_scanned} 支，無股票通過負乖離歷史篩選（條件：近 30 日負乖離天數 ≥ 24 天，且最後交易日乖離 0–5%）。分析結束。

**不繼續執行 Phase 2–5。**

## Phase 2：均線分析

> **重要：不要啟動子 agent，直接在主對話以 Python 抓取資料並計算均線。**

對 `matched` 中所有股票，使用標準函式庫 `urllib`（不需安裝額外套件）呼叫 **FinMind TaiwanStockPrice** API，取得近 6 個月收盤資料：

```python
import urllib.request, json, datetime

FINMIND_URL = "https://api.finmindtrade.com/api/v4/data"

def fetch_price(code, months=6):
    end = datetime.date.today().isoformat()
    year = datetime.date.today().year
    month = datetime.date.today().month - months
    if month <= 0:
        month += 12; year -= 1
    start = f"{year}-{month:02d}-01"
    url = f"{FINMIND_URL}?dataset=TaiwanStockPrice&data_id={code}&start_date={start}&end_date={end}"
    with urllib.request.urlopen(url, timeout=15) as r:
        data = json.loads(r.read())
    rows = data.get("data", [])
    closes = [float(row["close"]) for row in rows if row.get("close")]
    last_date = rows[-1]["date"] if rows else ""
    return closes, last_date
```

> FinMind 不受 TWSE SSL 限制，可正確取得 2026 年資料。免費 tier 無需 token，限速 30 req/day；設定 `FINMIND_API_TOKEN` 環境變數可提升上限。

計算指標：**MA5 / MA20 / MA60**，以及收盤對各均線的乖離百分比。

產業別使用 `get_stock_data(stock_code=code)` MCP 工具取得。

**最後交易日**：`deviation_scan` 結果已包含 `last_trading_date` 欄位；若為空，從上方 FinMind 資料取最後一筆的 `date`。

腳本輸出每支股票的 `ma_data`，包含：
- 基本資料（收盤、產業別、last_trading_date）
- 均線（MA5、MA20、MA60）
- 收盤距各均線乖離（vs_ma5、vs_ma20、vs_ma60，正值代表收盤在均線上方）
- 進場訊號判斷（ma60_reclaim / none）

## Phase 3：基本面分析

### 量化部分（即時資料）

對 `matched` 中所有股票，在主對話直接呼叫 MCP 工具 `get_fundamental_data(stock_code=code)`，取得：
- `eps_ttm`：近四季累計 EPS
- `eps_history`：近 12 季 EPS（計算年度趨勢）
- `per_quarterly`：各季 PER

### 質化部分（Gemini Search Grounding）

> **重要：不要啟動子 agent，直接在主對話以 Python 腳本呼叫 Gemini API。**

在主對話執行以下 Python 腳本（透過 Bash 工具），API key 從環境變數 `GEMINI_API_KEY` 讀取：

```python
import urllib.request, json, os, time

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"

def get_profile(code, name, industry):
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        return {
            "code": code, "name": name,
            "business_summary": "GEMINI_API_KEY 未設定",
            "revenue_structure": "無資料", "competitive_position": "無資料",
            "industry_outlook": "無資料", "source": "error"
        }
    prompt = f"""請查詢台灣上市公司 {code} {name}（產業別：{industry}）。
以繁體中文，嚴格按以下 JSON 格式回答，不要有其他文字：
{{
  "business_summary": "主力產品/服務與核心競爭力（60字內）",
  "revenue_structure": "主要收入來源與大致比例（80字內）",
  "competitive_position": "市場定位、市佔或護城河（80字內）",
  "industry_outlook": "所屬產業未來1-2年趨勢（80字內）"
}}
資訊不足的欄位填「資訊有限」，不得捏造。"""

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "tools": [{"google_search": {}}],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 512}
    }
    req = urllib.request.Request(
        f"{GEMINI_URL}?key={api_key}",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            result = json.loads(r.read())
        text = result["candidates"][0]["content"]["parts"][0]["text"].strip()
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"): text = text[4:]
        profile = json.loads(text.strip())
        profile.update({"code": code, "name": name, "source": "gemini-search"})
        return profile
    except Exception as e:
        return {
            "code": code, "name": name,
            "business_summary": f"查詢失敗：{str(e)[:80]}",
            "revenue_structure": "無資料", "competitive_position": "無資料",
            "industry_outlook": "無資料", "source": "error"
        }

# ===== 替換為實際 matched 股票清單 =====
stocks = [
    {"code": "2059", "name": "川湖", "industry": "電子工業"},
    # ... 其他股票
]

results = []
for s in stocks:
    results.append(get_profile(s["code"], s["name"], s["industry"]))
    time.sleep(3)

# 寫入 UTF-8 檔案避免終端機亂碼
import datetime
out_path = f"reports/taiwan-trading/gemini_profiles_{datetime.date.today()}.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(results, f, ensure_ascii=False, indent=2)
print(f"已寫入 {out_path}")
```

取得結果後，讀取 JSON 檔案，提取每支股票的 `business_summary`、`revenue_structure`、`competitive_position`、`industry_outlook` 供 Phase 4 使用。

> 若回傳 `source == "error"`，在報告中標注「業務資訊查詢失敗，請自行查閱公開說明書」。不得以 Claude 知識庫補充或捏造業務描述。

## Phase 4：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `deviation_stocks`（Phase 1 matched 清單）、所有 `ma_data`、所有 `fundamental_data`（量化 + 質化）
  — 輸出最終 Markdown 選股報告

## Phase 5：儲存（**必須執行，不可略過**）

risk-agent 輸出報告後，**立即**使用 Write 工具將完整報告儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_HHMM_select.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 為最後交易日日期，HHMM 為當前執行時間（同一天可多次執行，結果累計不互蓋）
- 若目錄不存在，先建立目錄再寫入
- 儲存完成後回覆：「✓ 報告已儲存至 reports/taiwan-trading/YYYY-MM-DD_HHMM_select.md」
