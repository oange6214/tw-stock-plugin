# tw-stock-plugin

台股金融分析插件集合。這個專案是 workflow layer，負責把研究、選股、風控、財務分析任務拆成 commands、skills、agents，並透過 `tw-stock-agent` 取得資料。

## 專案定位

在整個 workspace 中：

- `tw-stock-agent`：資料服務層
- `tw-stock-plugin`：工作流與插件層
- `tw-stock`：報告輸出工作區

## 插件架構

```text
commands
→ agents
→ skills
→ tw-stock-agent
→ tw-stock reports
```

補充文件：

- [Plugin Orchestration](./docs/ORCHESTRATION.md)
- [Output Schemas](./docs/output-schemas.md)

## 目前包含的插件

- `taiwan-trading`: 台股短波段交易流程
- `equity-research`: 個股研究與晨報
- `financial-analysis`: DCF、comps、模型分析
- `wealth-management`: 投組檢視、再平衡、客戶報告

## 與 tw-stock-agent 的關係

本專案不直接實作 market data provider，而是透過 `tw-stock-agent` 使用：

- `get_stock_data`
- `get_price_history`
- `get_realtime_data`
- `get_best_four_points`
- `get_market_overview`

## 目錄說明

### `commands/`

任務入口，描述完整工作流與執行順序。

### `agents/`

單一角色的指令定義，例如 market agent、risk agent、stock agent。

### `skills/`

方法論、檢查清單與輸出規範。

### `hooks/`

保留給插件生命週期掛鉤。目前大多數插件未實際使用。

## marketplace

插件入口由 [marketplace.json](./marketplace.json) 定義。

## 典型資料流

```text
command
→ agent orchestration
→ tw-stock-agent MCP tools/resources
→ analysis result
→ write report to tw-stock/reports
```

## 注意事項

- command 應專注在 orchestration，不要內嵌太多資料源細節
- agent 輸出建議採固定 JSON schema
- 共通的 API 限制、風控規則與格式要求，應逐步集中到 skill 文件
