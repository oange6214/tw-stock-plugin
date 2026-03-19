---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[篩選偏好，例如 '半導體強勢股' 或留空自動掃描]"
---

使用 multi-agent 架構執行選股，平行查詢以提升效率並控制 API rate limit。

## Phase 1：大盤環境與族群掃描

啟動：

- **market-agent**（`taiwan-trading/agents/market-agent.md`）
  — 查詢大盤環境、外資期貨部位、族群動能排行
  — 輸出：`market_data` JSON（含 `top_sectors` 與各族群股票清單）

若有提供篩選偏好，將偏好傳入 market-agent，優先掃描該族群。

## Phase 2：檢查 proceed 旗標

收到 `market_data` 後：

- `proceed: false` → 直接進入 Phase 5，跳過 Phase 3、4
- `proceed: true` → 繼續 Phase 3

## Phase 3：負乖離翻轉篩選（無數量限制）

對 `market_data.top_sectors` 各族群中**所有可取得的股票**執行篩選，無數量限制：

- **deviation-agent × N**（`taiwan-trading/agents/deviation-agent.md`）
  — 每個 Agent 負責一支股票（傳入股票代號）
  — 每批最多同時啟動 5 個（避免 API 超速），超過則分批執行直到全部完成
  — 篩選條件：
    1. 今日收盤由正乖離轉負乖離（20MA 基準）
    2. 近 30 日有 24 日以上（80%+）處於負乖離
  — 只保留 `matched: true` 的結果，輸出：`deviation_stocks` 陣列

若 `deviation_stocks` 為空 → 記錄「本日無負乖離翻轉標的」，繼續 Phase 4。

## Phase 4：個股深度分析（無數量限制）

對 `deviation_stocks` 中所有股票進行深度分析：

- **stock-agent × N**（`taiwan-trading/agents/stock-agent.md`）
  — 每個 Agent 負責一支股票（傳入股票代號）
  — 每批最多同時啟動 5 個（避免 API 超速），超過則分批執行直到全部完成
  — 輸出：每支股票的 `stock_data` JSON

## Phase 5：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `market_data`、`deviation_stocks`、所有 `stock_data`
  — 輸出最終 Markdown 選股報告

## Phase 6：儲存（**必須執行，不可略過**）

risk-agent 輸出報告後，**立即**使用 Write 工具將完整報告儲存：

- 路徑：`reports/taiwan-trading/YYYY-MM-DD_select.md`（相對於 terminal 工作目錄）
- YYYY-MM-DD 替換為今日日期
- 若目錄不存在，先建立目錄再寫入
- 儲存完成後回覆：「✓ 報告已儲存至 reports/taiwan-trading/YYYY-MM-DD_select.md」
