# Select Prompt

Use this prompt when the user wants to run the `taiwan-trading` stock selection workflow.

## Execution Steps

1. Read `taiwan-trading/commands/select.md`.
2. Read supporting files when needed:
   - `taiwan-trading/agents/risk-agent.md`
   - `taiwan-trading/skills/stock-screening/SKILL.md`
   - `taiwan-trading/skills/risk-management/SKILL.md`
3. If the user provides no tickers, follow the automatic market scan path.
4. If the user provides tickers, use those tickers as the selection universe.
5. Use `tw-stock-mcp` for deviation scan and related data gathering.
6. Save outputs to the workspace `reports/taiwan-trading/` directory.

## Suggested User Prompts

- `請依 docs/codex/prompts/select.md 執行台股短波段 select，必要時使用 tw-stock-mcp。`
- `請依 docs/codex/prompts/select.md，針對 2330 2454 2382 執行 select，必要時使用 tw-stock-mcp。`
