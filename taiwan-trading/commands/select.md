---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[可選：指定股票代號清單，例如 '2330 2454 2382'；留空則自動從 TWSE 抓取篩選清單]"
---

分析最近一個交易日的收盤資料，任何時間均可執行（不限定盤後，週末或假日同樣可用）。

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
1. 從 `STOCK_DAY_ALL` 抓取當日清單（4 位數代號、TradeValue > 1 億）
2. 抓取近 **6 個月** TWSE STOCK_DAY 資料（自動處理 SSL 憑證問題；5 個月資料量不足 91 筆門檻，全部股票會被 skip）
3. 計算 60MA（季線）乖離率，篩選：今日乖離 0~5%，近 30 日負乖離 ≥ 24 天
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

若 `matched` 為空 → 直接進入 Phase 3，回報「本日無符合標的」。

## Phase 2：個股深度分析

> **重要：子 agent 無法存取 MCP 工具，不可啟動 stock-agent。**
> 直接在主對話用 Python 抓取資料並計算技術指標。

對 `matched` 中所有股票，在主對話以 Python 計算技術指標。

> **注意**：`get_price_history` 與 `get_realtime_data` 底層使用 `twstock`（`requests` 函式庫），
> 受 TWSE SSL 憑證問題影響會失敗。改為直接用 `aiohttp`（已內建 SSL bypass）呼叫 TWSE STOCK_DAY API：

```python
import aiohttp, ssl, asyncio

SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE

async def fetch_twse_month(session, code, ym):
    url = f"https://www.twse.com.tw/exchangeReport/STOCK_DAY?date={ym}01&stockNo={code}&response=json"
    async with session.get(url, ssl=SSL_CTX, timeout=aiohttp.ClientTimeout(total=15)) as r:
        if r.status == 200:
            data = await r.json(content_type=None)
            if data.get("stat") == "OK":
                return [(row[0], float(row[6].replace(",", ""))) for row in data["data"]]
    return []
```

產業別可用 `get_stock_data(stock_code=code)` 取得（不受 SSL 問題影響）。

計算指標：RSI14、KD9、MA5/MA20/MA60，搭配乖離率進行評分。

腳本輸出每支股票的 `stock_data`，包含：
- 基本資料（收盤、均線、產業）
- 技術指標（RSI14、MACD、KD9）
- 量比（今日量 / 5日均量）
- 進場訊號判斷（breakout / ma60_reclaim / none）
- 評分（0–100）與分項說明

## Phase 3：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `deviation_stocks`（Phase 1 matched 清單）與所有 `stock_data`
  — 輸出最終 Markdown 選股報告

## Phase 4：儲存（**必須執行，不可略過**）

risk-agent 輸出報告後，**立即**使用 Write 工具將完整報告儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_HHMM_select.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 為最後交易日日期，HHMM 為當前執行時間（同一天可多次執行，結果累計不互蓋）
- 若目錄不存在，先建立目錄再寫入
- 儲存完成後回覆：「✓ 報告已儲存至 reports/taiwan-trading/YYYY-MM-DD_HHMM_select.md」
