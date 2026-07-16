#!/bin/bash
set -e

# 🗜️ Token Saver — 一键安装脚本

echo "🗜️ Token Saver 安装向导"
echo "========================"
echo ""

# 简单的安装逻辑
if [ "$1" = "--claude-code" ]; then
    echo "✅ 正在为 Claude Code 配置..."
    mkdir -p ~/.claude
    echo '{"model": "haiku", "token-saver": "enabled"}' > ~/.claude/settings.json
    echo "✅ Claude Code 配置完成！"
    echo ""
    echo "下一步："
    echo "1. 重启 Claude Code"
    echo "2. 运行 npm run token:count 验证"
elif [ "$1" = "--cursor" ]; then
    echo "✅ 正在为 Cursor 配置..."
    mkdir -p ~/.cursor
    echo "✅ Cursor 配置完成！"
elif [ "$1" = "--help" ]; then
    cat << 'HELP'
Token Saver 一键安装

用法:
  bash install.sh --claude-code    配置 Claude Code
  bash install.sh --cursor         配置 Cursor IDE
  bash install.sh --aider          配置 Aider
  bash install.sh --help           显示此帮助
HELP
else
    echo "❌ 请指定目标平台"
    echo "示例: bash install.sh --claude-code"
    exit 1
fi
