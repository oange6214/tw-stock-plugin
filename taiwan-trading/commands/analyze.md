---
description: 對單一台股標的進行兩週波段分析
argument-hint: "[股票代號，例如 2330]"
---

若有提供股票代號，請使用；否則詢問使用者要分析哪支股票。

使用 **stock-agent**（`taiwan-trading/agents/stock-agent.md`）對指定標的進行完整分析：

- 傳入股票代號給 stock-agent
- 收到 JSON 結果後，展開為完整的人讀報告（不只顯示 JSON）

## 報告展開格式

```markdown
## {代號} {名稱} — 兩週波段分析

**分析日期：** YYYY/MM/DD
**族群：** {sector}
**市場環境：** （簡述當日大盤）

### 技術面
- 收盤價：{close}（突破點 {breakout_point}）
- 量比：{volume_ratio}x
- 均線：5MA > 10MA > 20MA（多頭排列）
- RSI(14)：{rsi}
- MACD：{正/負}　KD：{狀態}　布林：{突破/未突破}

### 籌碼面
- 外資連買：{foreign_buy_days} 日
- 投信：{trust_buy ? "買超" : "未買超"}

### 進場計畫
| 項目 | 數值 |
|------|------|
| 進場價 | {entry_price} |
| 停損價 | {stop_loss}（-7%） |
| 第一停利 | {target_1}（+10%，出清 1/3） |
| 第二停利 | {target_2}（+15%，出清 1/3） |
| 時間停利 | D+8 個交易日出清剩餘 1/3 |
| 建議部位 | {position_size} |

### 評分：{score}/6 分　→　{qualified ? "符合進場條件" : "不符合：" + disqualify_reason}
```

完成後，使用 Write 工具將完整報告儲存至 `reports/taiwan-trading/YYYY-MM-DD_analyze_{代號}.md`（YYYY-MM-DD 為今日日期）。
