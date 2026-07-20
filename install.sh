#!/usr/bin/env bash
set -euo pipefail

# Token Saver — 一键安装脚本
# 用法: bash install.sh --all | --claude-code | --codex | --cursor | --aider | --project [路径] | --openai-compat | --help

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${TOKEN_SAVER_BIN:-$HOME/.local/bin}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARK_BEGIN="<!-- token-saver:begin -->"
MARK_END="<!-- token-saver:end -->"

is_windows() {
    [ "${OS:-}" = "Windows_NT" ] || [ -n "${MSYSTEM:-}" ]
}

# 幂等注入：目标文件已有标记块则整块替换，否则追加；首次修改前留 .token-saver.bak 备份
inject_block() { # $1=目标文件 $2=模板
    local file="$1" tmpl="$2" tmp
    mkdir -p "$(dirname "$file")"
    if [ -f "$file" ] && [ ! -f "$file.token-saver.bak" ]; then
        cp "$file" "$file.token-saver.bak"
    fi
    touch "$file"
    local rest
    # $() 会吞掉尾部空行，保证重复运行字节级幂等
    rest="$(awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$file")"
    {
        if [ -n "$rest" ]; then printf '%s\n\n' "$rest"; fi
        cat "$tmpl"
    } > "$file"
    echo "  ✅ 已注入: $file"
}

install_squeez() {
    mkdir -p "$BIN_DIR"
    cp "$ROOT/bin/squeez" "$BIN_DIR/squeez"
    chmod +x "$BIN_DIR/squeez"
    echo "  ✅ squeez → $BIN_DIR/squeez"
    # Windows: PowerShell/CMD 无法直接执行 bash 脚本，补 .cmd 垫片（批处理须 CRLF）
    # 烤入 Git Bash 绝对路径，避免命中 WSL 的 bash（后者读不懂 Windows 路径）
    if is_windows; then
        local winbash winscript
        if command -v cygpath >/dev/null 2>&1; then
            winbash="$(cygpath -w "$(command -v bash)")"
            winscript="$(cygpath -w "$BIN_DIR/squeez")"
        else
            winbash="$(command -v bash)"
            winscript="$BIN_DIR/squeez"
        fi
        printf '@echo off\r\n"%s" "%s" %%*\r\n' "$winbash" "$winscript" > "$BIN_DIR/squeez.cmd"
        echo "  ✅ squeez.cmd 垫片（PowerShell/CMD 可用）"
    fi
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "  ⚠️  $BIN_DIR 不在 PATH 中，请加入 PATH 后重开终端" ;;
    esac
}

install_node_tools() {
    if ! command -v node >/dev/null 2>&1; then
        echo "  ⚠️  未找到 node，跳过 token-usage / prompt-prefix-check"
        return
    fi
    mkdir -p "$BIN_DIR"
    local name win_node win_script
    for name in token-usage prompt-prefix-check; do
        cp "$ROOT/bin/$name.mjs" "$BIN_DIR/$name"
        chmod +x "$BIN_DIR/$name"
        echo "  ✅ $name → $BIN_DIR/$name"
        if is_windows; then
            if command -v cygpath >/dev/null 2>&1; then
                win_node="$(cygpath -w "$(command -v node)")"
                win_script="$(cygpath -w "$BIN_DIR/$name")"
            else
                win_node="$(command -v node)"
                win_script="$BIN_DIR/$name"
            fi
            printf '@echo off\r\n"%s" "%s" %%*\r\n' "$win_node" "$win_script" > "$BIN_DIR/$name.cmd"
            echo "  ✅ $name.cmd 垫片（PowerShell/CMD 可用）"
        fi
    done
}

install_tools() {
    install_squeez
    install_node_tools
}

install_claude() {
    echo "▶ 为 Claude Code 配置..."
    inject_block "$CLAUDE_DIR/CLAUDE.md" "$ROOT/config/claude-md.template"
    cp "$ROOT/config/reminder.md" "$CLAUDE_DIR/token-saver-reminder.md"
    cp "$ROOT/config/reminder-hook.mjs" "$CLAUDE_DIR/token-saver-reminder-hook.mjs"
    rm -f "$CLAUDE_DIR/token-saver-cache-hook.mjs"
    if command -v node >/dev/null 2>&1; then
        local hook_script="$CLAUDE_DIR/token-saver-reminder-hook.mjs"
        if is_windows && command -v cygpath >/dev/null 2>&1; then
            hook_script="$(cygpath -w "$hook_script")"
        fi
        [ -f "$CLAUDE_DIR/settings.json" ] && [ ! -f "$CLAUDE_DIR/settings.json.token-saver.bak" ] \
            && cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.token-saver.bak"
        node -e '
            const fs = require("fs"), p = process.argv[1] + "/settings.json";
            let s = {}; try { s = JSON.parse(fs.readFileSync(p, "utf8")) } catch {}
            s.hooks = s.hooks || {};
            const arr = (s.hooks.UserPromptSubmit || []).filter((hook) => !JSON.stringify(hook).includes("token-saver-reminder"));
            arr.push({ hooks: [{ type: "command", command: "node " + JSON.stringify(process.argv[2]) }] });
            s.hooks.UserPromptSubmit = arr;
            const pre = (s.hooks.PreToolUse || []).filter((hook) => !JSON.stringify(hook).includes("token-saver-cache-hook"));
            if (pre.length) s.hooks.PreToolUse = pre; else delete s.hooks.PreToolUse;
            fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
        ' "$CLAUDE_DIR" "$hook_script"
        echo "  ✅ 单行抗漂移 hook → settings.json (UserPromptSubmit)"
        echo "  ✅ 已迁移旧 bash reminder / 缓存字面检查 hook"
    else
        echo "  ⚠️  未找到 node，跳过 Claude hook 配置（全局规范仍生效）"
    fi
}

install_codex() {
    echo "▶ 为 Codex CLI 配置..."
    inject_block "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "$ROOT/config/claude-md.template"
}

echo "🗜️ Token Saver 安装向导"
echo "========================"

case "${1:-}" in
    --all)
        install_tools
        install_claude
        install_codex
        echo ""
        echo "完成！重启 Claude Code 与 Codex 后生效。"
        ;;
    --claude-code)
        install_tools
        install_claude
        echo ""
        echo "完成！下一步："
        echo "1. 重启 Claude Code（五项 Token Saver 规范生效）"
        echo "2. 想临时恢复白话：会话中说「白话模式」"
        echo "3. 验证: echo test | squeez"
        ;;
    --codex)
        install_tools
        install_codex
        echo ""
        echo "完成！重启 Codex 后五项 Token Saver 规范生效。"
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
  powershell -ExecutionPolicy Bypass -File .\install.ps1
                                  Windows PowerShell 一键配置 Claude Code + Codex
  bash install.sh --all             配置 Claude Code + Codex（推荐）
  powershell -ExecutionPolicy Bypass -File .\install.ps1 --codex
                                  Windows PowerShell 配置 Codex CLI
  bash install.sh --claude-code      配置 Claude Code（工具 + 全局规范）
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
        echo "❌ 请指定目标平台，示例: bash install.sh --all"
        echo "   查看帮助: bash install.sh --help"
        exit 1
        ;;
esac
