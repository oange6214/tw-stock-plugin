# 台股金融分析插件

台股短波段交易與個股研究的 Claude 插件系統，以兩週短波段策略為核心，整合 tw-stock-agent 台股即時數據。

## 插件架構

```
├── taiwan-trading/     # 台股兩週短波段交易系統（核心）
├── equity-research/    # 個股研究工具
├── financial-analysis/ # 財務分析工具
└── wealth-management/  # 投資組合管理工具
```

## MCP 資料來源：tw-stock-agent

**tw-stock-agent**（免費、開源）
- 涵蓋上市（TWSE）＋上櫃（TPEx）全市場
- 即時報價、技術指標、歷史數據
- 外資/投信/自營商籌碼資料
- GitHub：https://github.com/clsung/tw-stock-agent

### 安裝步驟（必要，約 5 分鐘）

**需求：** Python 3.11+、[uv](https://docs.astral.sh/uv/getting-started/installation/)

```bash
# 步驟 1：安裝 uv（若尚未安裝）
# Windows (PowerShell):
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# 步驟 2：Clone tw-stock-agent
git clone https://github.com/clsung/tw-stock-agent.git C:/Users/<你的帳號>/tw-stock-agent

# 步驟 3：安裝依賴
cd C:/Users/<你的帳號>/tw-stock-agent
uv sync

# 步驟 4：測試是否正常
uv run python mcp_server.py
```

### 設定 MCP

安裝完成後，在 `tw-stock-agent` 目錄下執行：

```bash
cd C:/Users/<你的帳號>/tw-stock-agent
claude mcp add tw-stock-agent uv -- run python mcp_server.py
```

或手動在 Claude Code 設定檔加入：

```json
{
  "mcpServers": {
    "tw-stock-agent": {
      "command": "uv",
      "args": ["run", "python", "mcp_server.py"],
      "cwd": "C:/Users/<你的帳號>/tw-stock-agent"
    }
  }
}
```

### tw-stock-agent 提供的工具

| 工具 | 說明 |
|------|------|
| `get_stock_data` | 公司概況、產業、市值 |
| `get_price_history` | 歷史 OHLCV 與成交量 |
| `get_realtime_data` | 即時股價與成交量 |
| `get_best_four_points` | 技術分析訊號 |
| `get_market_overview` | 大盤指數與市場摘要 |

---

## 插件說明

### 1. taiwan-trading（主力插件）

台股兩週短波段交易系統，強調「技術突破 + 籌碼跟隨 + 嚴格風控」。

| 指令 | 說明 |
|------|------|
| `/taiwan-trading:select` | 掃描全市場，選出 3-5 支符合短波段策略的標的 |
| `/taiwan-trading:analyze [代號]` | 對單一標的進行完整波段分析 |
| `/taiwan-trading:portfolio` | 檢視當前持倉是否符合持有條件 |
| `/taiwan-trading:risk` | 執行風控檢查（停損/部位/曝險） |
| `/taiwan-trading:market` | 分析大盤環境與主流族群 |

### 2. equity-research（個股研究）

| 指令 | 說明 |
|------|------|
| `/equity-research:screen` | 執行選股篩選 |
| `/equity-research:sector` | 台股產業景氣報告 |
| `/equity-research:earnings [代號]` | 季度財報分析報告 |
| `/equity-research:thesis [代號]` | 建立/更新投資論點 |
| `/equity-research:morning-note` | 盤前晨報 |

### 3. financial-analysis（財務分析）

| 指令 | 說明 |
|------|------|
| `/financial-analysis:dcf [代號]` | DCF 估值（結合同業比較） |
| `/financial-analysis:comps [代號]` | 同業比較分析 |
| `/financial-analysis:competitive-analysis` | 競爭格局分析 |
| `/financial-analysis:debug-model` | 財務模型稽核除錯 |

### 4. wealth-management（投資組合）

| 指令 | 說明 |
|------|------|
| `/wealth-management:rebalance` | 投資組合再平衡分析 |
| `/wealth-management:financial-plan` | 財務規劃 |
| `/wealth-management:client-report` | 投資績效報告 |

---

## 兩週短波段策略核心邏輯

```
族群掃描（資金動能）
    ↓
技術面篩選（突破、量能、均線多頭）
    ↓
籌碼面確認（外資/投信連續買超）
    ↓
進場計畫（進場點、部位大小 ≤ 25%）
    ↓
嚴格風控（停損 -5~8%、停利 +10/15%）
    ↓
時間管理（最長持有 10 個交易日）
```

## 注意事項

> 本插件提供的分析僅供參考，非投資建議。
> 股票投資有風險，請自行承擔投資決策責任。
> 請嚴格執行停損，資金管理優先於獲利追求。
