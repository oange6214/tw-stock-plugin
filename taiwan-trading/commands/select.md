---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[可選：指定股票代號清單，例如 '2330 2454 2382'；留空則自動從 TWSE 抓取篩選清單]"
---

使用 multi-agent 架構執行選股，平行查詢以提升效率並控制 API rate limit。
**設計為盤後執行（建議 15:30 後），使用 TWSE 當日收盤資料。**

輸出契約請對齊 `docs/output-schemas.md`，特別是：

- market-agent: 市場環境 JSON
- deviation-agent: 篩選結果 JSON
- stock-agent: 個股分析 JSON
- risk-agent: Markdown 報告 + 結構化摘要

## Phase 1：取得股票清單 & 確認大盤環境（同步執行）

以下兩件事**同時啟動**，都完成後才進入 Phase 2。

### 1A：TWSE 股票清單

若使用者有提供股票代號 → 直接使用，跳過抓取。

若未提供，使用 WebFetch 抓取當日上市股票清單：

```
GET https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL
```

從回傳的 JSON 陣列中初篩，**只保留**符合以下條件的股票：
- `Code` 為 **4 位純數字**（如 1234、2330）
- KY 股代號本身為純 4 位數字（如 2382、4560），**保留**
- 排除：代號含字母的特別股（如 1312A、2891B）、長度非 4 位的代號（如 910322、01001T）、DR
- `TradeValue`（成交金額）> `100000000`（1 億，排除冷門低流動性股票）

將初篩後的股票代號清單傳入 Phase 2。

### 1B：大盤環境確認

啟動 **market-agent**（`taiwan-trading/agents/market-agent.md`）查詢當日大盤環境。

- 若 `proceed: false` → **立即停止**，輸出大盤環境 JSON 並說明原因，不繼續後續 Phase。
- 若 `proceed: true` → 繼續 Phase 2。

## Phase 2：負乖離歷史比例篩選（無數量限制）

對 Phase 1A 清單中所有股票執行乖離率篩選：

- **deviation-agent × N**（`taiwan-trading/agents/deviation-agent.md`）
  — 每個 Agent 負責一支股票（傳入股票代號）
  — 每批最多同時啟動 5 個（避免 API 超速），超過則分批執行直到全部完成
  — 篩選條件：近 30 日有 24 日以上（80%+）處於負乖離（20MA 基準）
  — 只保留 `matched: true` 的結果，輸出：`deviation_stocks` 陣列

篩選完成後，**立即**將 `deviation_stocks` 儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_deviation.md`（相對於 terminal 工作目錄）
- 格式：Markdown 表格

```markdown
# YYYY-MM-DD 負乖離歷史篩選結果

**掃描：** {total_scanned} 支 → 命中：{total_matched} 支

| 代號 | 名稱 | 收盤價 | 20MA | 今日乖離(%) | 近30日負乖離比例(%) |
|------|------|--------|------|------------|-------------------|
...
```

若 `deviation_stocks` 為空 → 直接進入 Phase 4，回報「本日無符合標的」。

## Phase 3：個股深度分析（無數量限制）

對 `deviation_stocks` 中所有股票進行深度分析：

- **stock-agent × N**（`taiwan-trading/agents/stock-agent.md`）
  — 每個 Agent 負責一支股票（傳入股票代號）
  — 每批最多同時啟動 5 個（避免 API 超速），超過則分批執行直到全部完成
  — 輸出：每支股票的 `stock_data` JSON

## Phase 4：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `deviation_stocks` 與所有 `stock_data`
  — 輸出最終 Markdown 選股報告

## Phase 5：儲存（**必須執行，不可略過**）

risk-agent 輸出報告後，**立即**使用 Write 工具將完整報告儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_select.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 替換為今日日期
- 若目錄不存在，先建立目錄再寫入
- 儲存完成後回覆：「✓ 報告已儲存至 reports/taiwan-trading/YYYY-MM-DD_select.md」
