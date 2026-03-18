---
description: 執行台股兩週短波段選股（multi-agent 版本）
argument-hint: "[篩選偏好，例如 '半導體強勢股' 或留空自動掃描]"
---

使用 multi-agent 架構執行選股，平行查詢以提升效率並控制 API rate limit。

## Phase 1：平行啟動（同時執行，不等待）

同時啟動以下兩個 Agent：

- **market-agent**（`taiwan-trading/agents/market-agent.md`）
  — 查詢大盤環境、外資期貨部位、族群動能排行
  — 輸出：`market_data` JSON

若有提供篩選偏好，將偏好傳入 market-agent，優先掃描該族群。

## Phase 2：檢查 proceed 旗標

收到 `market_data` 後：

- `proceed: false` → 直接進入 Phase 4，跳過 Phase 3
- `proceed: true` → 繼續 Phase 3

## Phase 3：個股平行分析

根據 `market_data.top_sectors` 中的強勢族群，挑選 5–8 支候選標的，**同時**啟動多個 stock-agent：

- **stock-agent × N**（`taiwan-trading/agents/stock-agent.md`）
  — 每個 Agent 負責一支股票（傳入股票代號）
  — 最多同時啟動 5 個（避免 API 超速）
  — 輸出：每支股票的 `stock_data` JSON

## Phase 4：彙整與風控

啟動：

- **risk-agent**（`taiwan-trading/agents/risk-agent.md`）
  — 傳入 `market_data` 與所有 `stock_data`
  — 輸出最終 Markdown 選股報告

## Phase 5：儲存

使用 Write 工具將 risk-agent 輸出的完整報告儲存至：
`reports/taiwan-trading/YYYY-MM-DD_select.md`（YYYY-MM-DD 替換為今日日期）
