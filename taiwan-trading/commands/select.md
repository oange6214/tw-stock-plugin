---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[可選：指定股票代號清單，例如 '2330 2454 2382'；留空則自動從 GoodInfo 抓取篩選清單]"
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

### 1A：GoodInfo 篩選清單

若使用者有提供股票代號 → 直接使用，跳過 GoodInfo 抓取。

若未提供，使用瀏覽器工具（Claude in Chrome MCP）開啟以下 GoodInfo 篩選頁面，
等待頁面完整載入後（頁面標題出現「股票一覽」且不再顯示「資料載入中」），擷取股票清單：

```
https://goodinfo.tw/tw/StockList.asp?MARKET_CAT=%E8%87%AA%E8%A8%82%E7%AF%A9%E9%81%B8&INDUSTRY_CAT=%E6%88%91%E7%9A%84%E6%A2%9D%E4%BB%B6&FL_ITEM0=%E5%9D%87%E7%B7%9A%E4%B9%96%E9%9B%A2(%25)%E2%80%9360%E6%97%A5&FL_VAL_S0=0&FL_VAL_E0=5&FL_ITEM1=&FL_VAL_S1=&FL_VAL_E1=&FL_ITEM2=&FL_VAL_S2=&FL_VAL_E2=&FL_ITEM3=&FL_VAL_S3=&FL_VAL_E3=&FL_ITEM4=&FL_VAL_S4=&FL_VAL_E4=&FL_ITEM5=&FL_VAL_S5=&FL_VAL_E5=&FL_ITEM6=&FL_VAL_S6=&FL_VAL_E6=&FL_ITEM7=&FL_VAL_S7=&FL_VAL_E7=&FL_ITEM8=&FL_VAL_S8=&FL_VAL_E8=&FL_ITEM9=&FL_VAL_S9=&FL_VAL_E9=&FL_ITEM10=&FL_VAL_S10=&FL_VAL_E10=&FL_ITEM11=&FL_VAL_S11=&FL_VAL_E11=&FL_RULE0=%E7%94%A2%E6%A5%AD%E9%A1%9E%E5%88%A5%7C%7C%40%40ETF%40%40ETF&FL_RULE_CHK0=T&FL_RULE1=%E7%94%A2%E6%A5%AD%E9%A1%9E%E5%88%A5%7C%7C%40%40ETN%40%40ETN&FL_RULE_CHK1=T&FL_RULE2=&FL_RULE3=&FL_RULE4=&FL_RULE5=&FL_RANK0=&FL_RANK1=&FL_RANK2=&FL_RANK3=&FL_RANK4=&FL_RANK5=&FL_FD0=&FL_FD1=&FL_FD2=&FL_FD3=&FL_FD4=&FL_FD5=&FL_SHEET=%E4%BA%A4%E6%98%93%E7%8B%80%E6%B3%81&FL_SHEET2=%E6%97%A5&FL_MARKET=%E4%B8%8A%E5%B8%82%2F%E4%B8%8A%E6%AB%83&FL_QRY=%E6%9F%A5++%E8%A9%A2
```

**篩選說明：** 此 URL 已套用條件「60日均線乖離率 0~5%（正乖離）、上市/上櫃、排除 ETF/ETN」。

從擷取的清單中進行二次過濾，**只保留**符合以下條件的股票：
- 代號為 **4 位純數字**（如 1234、2330）
- KY 股代號本身為純 4 位數字（如 2382、4560），**保留**
- 排除：代號含字母的特別股（如 1312A、2891B）、長度非 4 位的代號（如 910322、01001T）、DR

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
