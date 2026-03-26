# `tw-stock-plugin` GitHub 發布摘要

這個 repo 適合作為 **Claude plugin + Codex workflow knowledge base** 一起發布。

## 應發布內容

- Claude plugin 結構與 manifest
- `commands/`
- `skills/`
- `agents/`
- `hooks/`
- `marketplace.json`
- `README.md`
- `AGENTS.md`
- `docs/codex/`

## 不應發布內容

- `.mcp.json`
- `reports/`
- 本機虛擬環境或快取
- 個人筆記與暫存檔

## 發布前檢查

在此目錄執行：

```bash
git status --short
```

確認沒有以下不該提交的內容：

- `.mcp.json`
- `reports/`
- `.venv/`
- `__pycache__/`
- `.env`

## 目前重點

這個 repo 現在已具備：

- Claude plugin 用的原始結構
- Codex 用的 `AGENTS.md`
- Codex 用的 `docs/codex/prompts/*.md`

## 建議提交順序

```bash
git add .gitignore README.md AGENTS.md docs/codex
git status
```

如果你也要一起提交其他既有修改，請再確認：

- `taiwan-trading/agents/risk-agent.md`
- `taiwan-trading/agents/stock-agent.md`
- `taiwan-trading/commands/select.md`

這三個檔案目前也有未提交變更，請確認是否屬於你要一起發布的內容。
