# tw-stock-plugin

台股金融分析插件集合。這個專案是 workflow layer，負責把研究、選股、風控、財務分析任務拆成 commands、skills、agents，並透過 `tw-stock-mcp` 取得資料。

## 專案定位

在整個 workspace 中：

- `tw-stock-mcp`：資料服務層
- `tw-stock-plugin`：工作流與插件層
- `tw-stock`：報告輸出工作區

## 插件架構

```text
commands
→ agents
→ skills
→ tw-stock-mcp
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

## 與 tw-stock-mcp 的關係

本專案不直接實作 market data provider，而是透過 `tw-stock-mcp` 使用：

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
→ tw-stock-mcp MCP tools/resources
→ analysis result
→ write report to tw-stock/reports
```

## 安裝

在 Claude Code 中透過 marketplace 安裝：

```
/install-plugin https://github.com/oange6214/tw-stock-plugin
```

安裝後需同步安裝 `tw-stock-mcp`（資料層），並在工作目錄建立 `.mcp.json`。詳見 [tw-stock-mcp README](https://github.com/oange6214/tw-stock-mcp)。

## 更新

Claude Code 的 plugin cache 不會自動同步 GitHub 最新版。更新步驟：

```bash
# 1. 拉取最新版本
git pull

# 2. 同步到 Claude Code plugin cache
bash update-plugin.sh

# 3. 重啟 Claude Code 讓變更生效
```

`update-plugin.sh` 會自動偵測 cache 路徑（支援 macOS / Linux / Windows），將最新的 commands、agents、skills 複製到所有已安裝的版本目錄。

## 注意事項

- command 應專注在 orchestration，不要內嵌太多資料源細節
- agent 輸出一律使用人讀 Markdown 格式，不使用 JSON
- 共通的 API 限制、風控規則與格式要求，應逐步集中到 skill 文件
