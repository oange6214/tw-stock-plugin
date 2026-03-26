# Codex Support

This directory adds a Codex-friendly layer on top of the existing Claude plugin structure.

## Purpose

- Keep Claude plugin files unchanged
- Give Codex stable prompt templates and routing guidance
- Reuse the same commands and skills as the source of truth

## How To Use

Open the parent workspace in Codex and use prompts like:

- `請依 docs/codex/prompts/thesis.md，為 2330 建立投資 thesis，必要時使用 tw-stock-mcp。`
- `請依 docs/codex/prompts/earnings.md，整理 2330 最新財報重點，必要時使用 tw-stock-mcp。`
- `請依 docs/codex/prompts/dcf.md，為 2317 建立 DCF 估值分析，必要時使用 tw-stock-mcp。`
- `請依 docs/codex/prompts/select.md，執行台股短波段 select，必要時使用 tw-stock-mcp。`

## Notes

- Codex reads files directly; it does not install Claude plugins.
- MCP access still comes from the workspace-level `.mcp.json`.
- The canonical workflows remain in `commands/` and `skills/`.
