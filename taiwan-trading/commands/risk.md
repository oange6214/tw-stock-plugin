---
description: 執行波段操作風險控管檢查
argument-hint: "[股票代號或留空檢查全部持倉]"
---

載入 `risk-management` 技能，執行嚴格的波段操作風控檢查。

風控重點：
- 單筆停損是否設定（5-8%）
- 持倉部位是否過度集中
- 總部位曝險是否超過設定上限
- 大盤環境是否適合進攻
- 是否有即將公布財報或重大訊息的風險

完成風控檢查後，使用 Write 工具將完整報告儲存至 `reports/taiwan-trading/YYYY-MM-DD_risk.md`（YYYY-MM-DD 替換為今日日期）。
