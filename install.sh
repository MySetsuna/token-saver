#!/usr/bin/env bash
set -euo pipefail

# 🗜️ Token Saver — 一键安装脚本
# 用法: bash install.sh --claude-code | --codex | --cursor | --aider | --project [路径] | --openai-compat | --help

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${TOKEN_SAVER_BIN:-$HOME/.local/bin}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARK_BEGIN="<!-- token-saver:begin -->"
MARK_END="<!-- token-saver:end -->"

# 幂等注入：目标文件已有标记块则整块替换，否则追加；首次修改前留 .token-saver.bak 备份
inject_block() { # $1=目标文件 $2=模板
    local file="$1" tmpl="$2" tmp
    mkdir -p "$(dirname "$file")"
    if [ -f "$file" ] && [ ! -f "$file.token-saver.bak" ]; then
        cp "$file" "$file.token-saver.bak"
    fi
    touch "$file"
    tmp="$(mktemp)"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$file" > "$tmp"
    { cat "$tmp"; echo ""; cat "$tmpl"; } > "$file"
    rm -f "$tmp"
    echo "  ✅ 已注入: $file"
}

install_squeez() {
    mkdir -p "$BIN_DIR"
    cp "$ROOT/bin/squeez" "$BIN_DIR/squeez"
    chmod +x "$BIN_DIR/squeez"
    echo "  ✅ squeez → $BIN_DIR/squeez"
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "  ⚠️  $BIN_DIR 不在 PATH 中，请加入 PATH 后重开终端" ;;
    esac
}

echo "🗜️ Token Saver 安装向导"
echo "========================"

case "${1:-}" in
    --claude-code)
        echo "▶ 为 Claude Code 配置..."
        install_squeez
        inject_block "$CLAUDE_DIR/CLAUDE.md" "$ROOT/config/claude-md.template"
        echo ""
        echo "完成！下一步："
        echo "1. 重启 Claude Code（精简 + 文言输出规范默认生效）"
        echo "2. 想临时恢复白话：会话中说「白话模式」"
        echo "3. 验证: echo test | squeez"
        ;;
    --codex)
        echo "▶ 为 Codex CLI 配置..."
        install_squeez
        inject_block "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "$ROOT/config/claude-md.template"
        echo ""
        echo "完成！重启 Codex 后全局规范默认生效（含文言模式）。"
        ;;
    --cursor)
        echo "▶ 为 Cursor 配置（当前目录: $PWD）..."
        inject_block "$PWD/.cursorrules" "$ROOT/config/cursorrules.template"
        echo ""
        echo "完成！在目标项目根目录运行本命令可为其他项目配置。"
        ;;
    --aider)
        echo "▶ 为 Aider 配置..."
        mkdir -p "$HOME/.token-saver"
        cp "$ROOT/config/aider-conventions.template" "$HOME/.token-saver/CONVENTIONS.md"
        echo "  ✅ 规范 → ~/.token-saver/CONVENTIONS.md"
        if [ ! -f "$HOME/.aider.conf.yml" ]; then
            printf 'read: ["~/.token-saver/CONVENTIONS.md"]\nedit-format: diff\n' > "$HOME/.aider.conf.yml"
            echo "  ✅ 已创建 ~/.aider.conf.yml (read + diff 模式)"
        elif grep -q "token-saver/CONVENTIONS.md" "$HOME/.aider.conf.yml"; then
            echo "  ✅ ~/.aider.conf.yml 已包含 Token Saver 规范"
        else
            echo "  ⚠️  ~/.aider.conf.yml 已存在，请手动加入:"
            echo '      read: ["~/.token-saver/CONVENTIONS.md"]'
            echo '      edit-format: diff'
        fi
        ;;
    --project)
        TARGET="${2:-$PWD}"
        echo "▶ 为项目 $TARGET 注入 Token Saver 规范..."
        inject_block "$TARGET/CLAUDE.md" "$ROOT/config/claude-md.template"
        ;;
    --openai-compat)
        cat << 'EOF'
▶ 通用 OpenAI 兼容端点方案（信息，不改动任何配置）:

1. 输入去重代理 tamp:  npx -y @sliday/tamp
   然后把客户端 base_url 指向 http://localhost:7778/v1
2. 代码库瘦身:          npx -y repomix
3. Prompt 缓存锚定:     静态内容（system/tools/文档）在前，动态对话在后，
                        静态区严禁时间戳等动态变量。
EOF
        ;;
    --help)
        cat << 'HELP'
Token Saver 一键安装

用法:
  bash install.sh --claude-code      配置 Claude Code（squeez + 全局规范，文言模式默认启用）
  bash install.sh --codex            配置 Codex CLI（squeez + 全局 AGENTS.md 规范）
  bash install.sh --cursor           为当前项目写入 .cursorrules
  bash install.sh --aider            配置 Aider（CONVENTIONS + diff 模式）
  bash install.sh --project [路径]   为指定项目注入 CLAUDE.md 规范
  bash install.sh --openai-compat    打印通用 API 端点优化指引
  bash install.sh --help             显示此帮助

环境变量:
  TOKEN_SAVER_BIN     squeez 安装目录 (默认 ~/.local/bin)
  CLAUDE_CONFIG_DIR   Claude 配置目录 (默认 ~/.claude)

所有写入均幂等（重复运行只更新标记块），首次修改前自动备份 *.token-saver.bak。
HELP
        ;;
    *)
        echo "❌ 请指定目标平台，示例: bash install.sh --claude-code"
        echo "   查看帮助: bash install.sh --help"
        exit 1
        ;;
esac
