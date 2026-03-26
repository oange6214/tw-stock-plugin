# Earnings Prompt

Use this prompt when the user wants an earnings preview, earnings review, or post-result update.

## Execution Steps

1. Read the most relevant command under `equity-research/commands/`:
   - `earnings-preview.md`
   - `earnings.md`
   - `model-update.md`
2. Read related skills under `equity-research/skills/`.
3. Use `tw-stock-mcp` for price context and supporting stock data.
4. Compare reported or expected results against prior trend and thesis drivers.
5. Save the output to the workspace `reports/{ticker}-earnings.md` unless the user requests another path.
