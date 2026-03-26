# DCF Prompt

Use this prompt when the user wants a discounted cash flow valuation or valuation memo.

## Execution Steps

1. Read `financial-analysis/commands/dcf.md`.
2. Read `financial-analysis/skills/dcf-model/SKILL.md`.
3. Use `tw-stock-mcp` and local data sources to collect operating and market inputs.
4. Build the valuation step by step.
5. If an Excel model exists, reuse `financial-analysis/skills/dcf-model/scripts/validate_dcf.py` when applicable.
6. Save the output to the workspace `reports/{ticker}-dcf.md` unless the user requests another path.
