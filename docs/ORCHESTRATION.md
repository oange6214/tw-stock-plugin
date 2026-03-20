# Plugin Orchestration

`tw-stock-plugin` 是 workflow layer，不直接提供資料，而是編排分析流程。

## 插件結構

- `commands/`: 任務入口，定義步驟與輸出要求
- `agents/`: 子角色，負責單一分析任務
- `skills/`: 分析框架與操作規則
- `hooks/`: 事件掛鉤，目前多數插件未實際使用

## 典型流程

以 `taiwan-trading:select` 為例：

1. 決定股票清單來源
2. 執行市場環境檢查
3. 平行跑個股或乖離分析 agent
4. 交給 risk agent 彙整成最終報告
5. 寫入 `tw-stock/reports/...`

## 分層原則

- command 負責 orchestration
- agent 負責單一角色輸出
- skill 負責方法論與限制
- 資料查詢由 `tw-stock-mcp` 負責

## 維護建議

- command 不要內嵌過多資料源細節
- agent 輸出盡量使用固定 JSON schema
- 共通限制應集中在 skill 或 shared policy 文件
