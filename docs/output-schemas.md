# Output Schemas

這份文件定義 plugin 層建議遵守的輸出契約，降低 command 與 agent 之間的耦合。

## Market Agent / `get_market_overview` 直接呼叫

`get_market_overview` MCP 工具回傳欄位：

```json
{
  "date": "2026-03-20T15:30:00",
  "taiex": {
    "index_name": "TAIEX",
    "current_value": 20000.5,
    "change_points": 50.2,
    "change_percentage": 0.25
  },
  "volume": 5000000000,
  "turnover": { "amount": 350000000000.0, "currency": "TWD" },
  "advancing_stocks": 450,
  "declining_stocks": 300,
  "unchanged_stocks": 80,
  "market_status": "closed",
  "reference_stock": "TWSE_MI_INDEX",
  "updated_at": "2026-03-20T15:30:00"
}
```

**注意：** 當 MI_INDEX 解析失敗時，`reference_stock` 為 `"0050"` 或 `"0050_PROXY"`，
且 `taiex.index_name` 為 `"0050_PROXY"`。此時 `advancing_stocks`、`declining_stocks` 等欄位為 null。

select.md 判斷 proceed/stop 邏輯由 orchestrator 自行根據以上欄位判斷，
不再透過 market-agent 子 agent（子 agent 無法存取 MCP 工具）。

## `get_deviation_scan` 工具輸出

```json
{
  "total_stocks": 378,
  "total_scanned": 350,
  "matched_count": 4,
  "matched": [
    {
      "code": "2330",
      "name": "台積電",
      "close": 945.0,
      "ma20": 940.5,
      "today_deviation": 0.48,
      "negative_days_30": 26,
      "negative_ratio_30": 86.7,
      "matched": true
    }
  ],
  "months": ["20251201", "20260101", "20260201", "20260301"]
}
```

`skipped: true` 的股票表示歷史資料不足（< 51 筆收盤），不會出現在 `matched` 中。

## Stock Agent

建議輸出：

```json
{
  "stock_code": "2330",
  "name": "台積電",
  "trend": "neutral",
  "entry_plan": {
    "entry_price": 945.0,
    "stop_loss": 905.0,
    "take_profit": 1035.0
  },
  "risks": ["market_weakness"],
  "data_source": "tw-stock-mcp"
}
```

## Risk Agent

最終輸出可為 Markdown，但建議同時保留一份結構化摘要：

```json
{
  "report_type": "taiwan_trading_select",
  "trading_date": "2026-03-20",
  "proceed": false,
  "risk_level": "high",
  "selected_stocks": [],
  "report_path": "reports/taiwan-trading/2026-03-20_select.md"
}
```
