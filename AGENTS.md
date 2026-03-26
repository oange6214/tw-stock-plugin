# tw-stock-plugin Codex Guide

This repository is primarily a Claude plugin knowledge base, but it also supports Codex.

## Core Rule

Do not break the existing Claude plugin structure.
Keep `.claude-plugin/`, `commands/`, `skills/`, `agents/`, `hooks/`, and manifests compatible with Claude.

## How Codex Should Work Here

1. Treat this repo as a read-first workflow and methodology library.
2. Map user requests to the closest command under these directories:
   - `taiwan-trading/commands/`
   - `equity-research/commands/`
   - `financial-analysis/commands/`
   - `wealth-management/commands/`
3. Read the corresponding `skills/*/SKILL.md` files before executing the task.
4. Use MCP server `tw-stock-mcp` from the parent workspace whenever market or stock data is needed.
5. Save outputs to the workspace-level `reports/` directory unless the user requests another path.

## Task Routing

- Trading or market context: start with `taiwan-trading/`
- Earnings, thesis, sector, initiation: start with `equity-research/`
- DCF, comps, model, deck checks: start with `financial-analysis/`
- Portfolio review, rebalance, client deliverables: start with `wealth-management/`

## Codex Prompt Templates

Use these templates under `docs/codex/prompts/`:

- `thesis.md`
- `earnings.md`
- `initiate.md`
- `sector.md`
- `dcf.md`
- `market.md`
- `select.md`
- `screen.md`
- `portfolio.md`
- `rebalance.md`
