---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[可選：指定股票代號清單，例如 '2330 2454 2382'；留空則自動從 TWSE 抓取篩選清單]"
---

使用 MCP 工具 + multi-agent 架構執行選股，盡量平行執行以提升效率。
**設計為盤後執行（建議 15:30 後），使用 TWSE 當日收盤資料。**

輸出契約請對齊 `docs/output-schemas.md`，特別是：

- market-agent: 市場環境 JSON
- stock-agent: 個股分析 JSON
- risk-agent: Markdown 報告 + 結構化摘要

## Phase 1：確認大盤環境

直接在主對話呼叫 MCP 工具 `get_market_overview`（**不要啟動子 agent**，子 agent 無法存取 MCP 工具）。

根據回傳結果判斷：
- 若 TAIEX 指數異常（跌幅 > 2% 或指數明顯崩跌） → **立即停止**，輸出大盤狀況並說明原因，不繼續後續 Phase。
- 否則 → 繼續 Phase 2。

輸出大盤 JSON（對齊 output-schemas.md market-agent 格式）：

```json
{
  "proceed": true,
  "taiex": { "current_value": 20000, "change_points": 50, "change_percentage": 0.25 },
  "market_status": "closed",
  "data_warning": "..."
}
```

若 `reference_stock` 為 `"0050"` 或 `"0050_PROXY"`，表示 MI_INDEX 解析失敗，在 `data_warning` 欄位說明，但仍繼續（不因此停止）。

## Phase 2：負乖離歷史比例篩選

### 若使用者提供股票代號

直接以逗號分隔字串傳入 Phase 2 掃描，跳過自動清單抓取。

### 若未提供股票代號（自動掃描全市場）

呼叫 MCP 工具 `get_deviation_scan`，**不傳入任何參數**（工具會自動抓取當日 TWSE 清單並過濾流動性）：

```
get_deviation_scan(stock_codes="")
```

工具內部會：
1. 從 `STOCK_DAY_ALL` 抓取當日清單（4 位數代號、TradeValue > 1 億）
2. 抓取近 5 個月 TWSE STOCK_DAY 資料（自動處理 SSL 憑證問題）
3. 計算 60MA（季線）乖離率，篩選：今日乖離 0~5%，近 30 日負乖離 ≥ 24 天
4. 回傳 `matched` 陣列

### 若提供了股票代號

呼叫 MCP 工具 `get_deviation_scan`，傳入代號清單：

```
get_deviation_scan(stock_codes="2330,2454,2382,...")
```

### 儲存篩選結果

工具回傳後，立即將 `matched` 清單儲存（**必須執行**）：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_deviation.md`（相對於 terminal 工作目錄）
- 若目錄不存在先建立

```markdown
# YYYY-MM-DD 負乖離歷史篩選結果

**掃描：** {total_scanned} 支 → 命中：{total_matched} 支

| 代號 | 名稱 | 收盤價 | 60MA | 今日乖離(%) | 近30日負乖離比例(%) |
|------|------|--------|------|------------|-------------------|
...
```

若 `matched` 為空 → 直接進入 Phase 4，回報「本日無符合標的」。

## Phase 3：個股深度分析

對 `matched` 中所有股票啟動 **stock-agent**（`taiwan-trading/agents/stock-agent.md`）：

- 每個 Agent 負責一支股票（傳入股票代號）
- 每批最多同時啟動 5 個（避免 API 超速），超過則分批執行
- 輸出：每支股票的 `stock_data` JSON

## Phase 4：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `deviation_stocks`（Phase 2 matched 清單）與所有 `stock_data`
  — 輸出最終 Markdown 選股報告

## Phase 5：儲存（**必須執行，不可略過**）

risk-agent 輸出報告後，**立即**使用 Write 工具將完整報告儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_select.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 替換為今日日期
- 若目錄不存在，先建立目錄再寫入
- 儲存完成後回覆：「✓ 報告已儲存至 reports/taiwan-trading/YYYY-MM-DD_select.md」
