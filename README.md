# tw-stock-plugin

## Codex 使用方式

這個 repo 除了可作為 Claude plugin 的知識庫，也可以直接給 Codex 當作工作流與提示模板來源。

### Codex 需要什麼

- 本 repo 內的 `AGENTS.md`
- 本 repo 內的 `docs/codex/prompts/*.md`
- workspace 根目錄的 `.mcp.json`
- 同一個 workspace 下的 `tw-stock-mcp/`

### 建議 workspace 結構

```text
Finances/
├─ .mcp.json
├─ tw-stock-plugin/
└─ tw-stock-mcp/
```

### Claude 怎麼用

- 依照原本流程安裝 `tw-stock-plugin`
- 在含有 `.mcp.json` 的 workspace 中啟動 Claude CLI
- 使用原本的 plugin commands

### Codex 怎麼用

- 用 Codex 開啟 workspace 根目錄
- 讓 Codex 讀取 `tw-stock-plugin/AGENTS.md`
- 依 `docs/codex/prompts/*.md` 下任務

例如：

```text
請依 docs/codex/prompts/thesis.md，為 2330 建立投資 thesis，必要時使用 tw-stock-mcp。
```

```text
請依 docs/codex/prompts/dcf.md，為 2317 建立 DCF 估值分析，必要時使用 tw-stock-mcp。
```

更完整的跨工具安裝方式，請參考 workspace 層級的 `SETUP.md`。


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

## 外部依賴

### tw-stock-mcp（資料層）

本專案透過 `tw-stock-mcp` MCP 工具取得市場資料：

- `get_stock_data`、`get_price_history`、`get_realtime_data`
- `get_best_four_points`、`get_market_overview`
- `get_deviation_scan`、`get_fundamental_data`

### FinMind（均線計算）

Phase 2 均線分析使用 [FinMind](https://finmindtrade.com/) TaiwanStockPrice API（免費 tier 無需 token）。可設定 `FINMIND_API_TOKEN` 環境變數提升速率限制。

### Gemini API（公司業務查詢）

Phase 3 質化分析（業務描述、競爭地位、產業展望）使用 **Gemini Flash Lite（`gemini-flash-lite-latest`）+ Search Grounding**，透過即時網路搜尋取得準確的公司資訊，避免 Claude 知識庫對中小型股、KY 股的描述錯誤。

**設定方式（必須，且不可寫入 git）：**

```bash
# Windows — 存入使用者環境變數，不在任何檔案中
setx GEMINI_API_KEY "your-api-key"
# 設定後需重啟 Claude Code 才生效
```

> ⚠️ **安全注意事項：** API key 絕對不可寫入任何被 git 追蹤的檔案（`.env`、config 等）。請使用作業系統環境變數或 secret manager 管理。

取得 API key：[Google AI Studio](https://aistudio.google.com/app/apikey)

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
