# Thesis Prompt

Use this prompt when the user wants to create or update an investment thesis for a Taiwan stock.

## Inputs To Confirm

- Ticker or company name
- Time horizon
- Long, short, or neutral view
- Whether this is a new thesis or an update

## Execution Steps

1. Read `equity-research/commands/thesis.md`.
2. Read `equity-research/skills/thesis-tracker/SKILL.md`.
3. Use `tw-stock-mcp` tools to gather current market, company, and price context when needed.
4. Build a thesis with core view, supporting pillars, risks, catalysts, and monitoring checklist.
5. Save the output to the workspace `reports/{ticker}-thesis.md` unless the user requests another path.
