#!/bin/bash
# update-plugin.sh
# 將 tw-stock-plugin 的最新內容同步到 Claude Code plugin cache
# 用法：bash update-plugin.sh

set -e

PLUGIN_NAME="tw-stock-trading"
PLUGIN_DIR="taiwan-trading"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)/$PLUGIN_DIR"

# 找出 Claude Code plugin cache 根目錄（跨平台）
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OS" == "Windows_NT" ]]; then
  CLAUDE_DIR="$USERPROFILE/.claude"
else
  CLAUDE_DIR="$HOME/.claude"
fi

CACHE_BASE="$CLAUDE_DIR/plugins/cache/$PLUGIN_NAME/$PLUGIN_DIR"
MARKETPLACE_DIR="$CLAUDE_DIR/plugins/marketplaces/$PLUGIN_NAME/$PLUGIN_DIR"

echo "=== tw-stock-plugin 更新工具 ==="
echo "來源：$SOURCE_DIR"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ 找不到 source 目錄：$SOURCE_DIR"
  exit 1
fi

# 同步 cache（所有版本目錄）
UPDATED=0
if [ -d "$CLAUDE_DIR/plugins/cache/$PLUGIN_NAME" ]; then
  for VERSION_DIR in "$CLAUDE_DIR/plugins/cache/$PLUGIN_NAME/$PLUGIN_DIR"/*/; do
    if [ -d "$VERSION_DIR" ]; then
      cp -r "$SOURCE_DIR/agents" "$VERSION_DIR/" 2>/dev/null || true
      cp -r "$SOURCE_DIR/commands" "$VERSION_DIR/" 2>/dev/null || true
      cp -r "$SOURCE_DIR/skills" "$VERSION_DIR/" 2>/dev/null || true
      echo "✓ 更新 cache：$VERSION_DIR"
      UPDATED=1
    fi
  done
fi

# 同步 marketplace
if [ -d "$MARKETPLACE_DIR" ]; then
  cp -r "$SOURCE_DIR/agents" "$MARKETPLACE_DIR/" 2>/dev/null || true
  cp -r "$SOURCE_DIR/commands" "$MARKETPLACE_DIR/" 2>/dev/null || true
  cp -r "$SOURCE_DIR/skills" "$MARKETPLACE_DIR/" 2>/dev/null || true
  echo "✓ 更新 marketplace：$MARKETPLACE_DIR"
  UPDATED=1
fi

if [ $UPDATED -eq 0 ]; then
  echo "⚠️  找不到已安裝的 plugin cache，請先在 Claude Code 安裝此 plugin。"
  exit 1
fi

echo ""
echo "✅ 更新完成。請重啟 Claude Code 讓變更生效。"
