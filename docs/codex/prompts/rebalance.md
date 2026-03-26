# Rebalance Prompt

Use this prompt when the user wants a portfolio rebalance plan.

## Execution Steps

1. Read `wealth-management/commands/rebalance.md`.
2. Read `wealth-management/skills/portfolio-rebalance/SKILL.md`.
3. If short-term trading context matters, also read `taiwan-trading/commands/portfolio.md`.
4. Use `tw-stock-mcp` for market conditions and holding-level context.
5. Recommend specific actions such as trim, add, rotate, hold, or raise cash.
6. Save the output to the workspace `reports/rebalance-{date}.md` unless the user requests another path.
