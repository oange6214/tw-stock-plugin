# Portfolio Prompt

Use this prompt when the user wants portfolio review or risk-focused position analysis.

## Execution Steps

1. Read the closest relevant command under `wealth-management/commands/`.
2. Read the closest supporting skills under `wealth-management/skills/`.
3. If the request is trading-oriented, also check `taiwan-trading/commands/portfolio.md`.
4. Use `tw-stock-mcp` for market and stock-level context.
5. Evaluate concentration, sector balance, liquidity, drawdown risk, and thesis overlap.
6. Save the output to the workspace `reports/portfolio-{date}.md` unless the user requests another path.
