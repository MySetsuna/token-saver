#!/usr/bin/env bash
# squeez 与 install.sh 的最小自检
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
S=bin/squeez
fail() { echo "❌ $1"; exit 1; }

# 1. ANSI 剥离
out=$(printf '\033[31mERROR red\033[0m\n' | bash $S)
[ "$out" = "ERROR red" ] || fail "ANSI 剥离: got [$out]"

# 2. 重复行折叠
out=$(for i in $(seq 50); do echo same; done | bash $S)
[ "$out" = "same (x50)" ] || fail "重复折叠: got [$out]"

# 3. 截断保留错误行且总量受控
out=$( { seq 1 500; echo "ERROR: boom"; seq 501 1000; } | bash $S )
echo "$out" | grep -q "ERROR: boom" || fail "截断后错误行丢失"
n=$(echo "$out" | wc -l)
[ "$n" -lt 200 ] || fail "截断失效: $n 行"

# 4. 短输出原样通过
out=$(printf 'a\nb\nc\n' | bash $S)
[ "$out" = "$(printf 'a\nb\nc')" ] || fail "短输出被改动"

# 5. install.sh --claude-code 在沙箱 HOME 中幂等
SANDBOX=$(mktemp -d)
HOME="$SANDBOX" bash install.sh --claude-code > /dev/null
HOME="$SANDBOX" bash install.sh --claude-code > /dev/null   # 第二次，验证幂等
[ -x "$SANDBOX/.local/bin/squeez" ] || fail "squeez 未安装"
if [ "${OS:-}" = "Windows_NT" ]; then
    [ -f "$SANDBOX/.local/bin/squeez.cmd" ] || fail "Windows 垫片未安装"
fi
[ "$(grep -c 'token-saver:begin' "$SANDBOX/.claude/CLAUDE.md")" = "1" ] || fail "CLAUDE.md 注入不幂等"
grep -q "微言大义" "$SANDBOX/.claude/CLAUDE.md" || fail "文言协议未默认注入"
grep -qi "caveman" "$SANDBOX/.claude/CLAUDE.md" || fail "caveman 协议未默认注入"
h2=$(md5sum "$SANDBOX/.claude/CLAUDE.md")
HOME="$SANDBOX" bash install.sh --claude-code > /dev/null   # 第三次，验证字节级幂等
[ "$h2" = "$(md5sum "$SANDBOX/.claude/CLAUDE.md")" ] || fail "注入非字节级幂等"
HOME="$SANDBOX" bash install.sh --codex > /dev/null
grep -q "token-saver:begin" "$SANDBOX/.codex/AGENTS.md" || fail "codex AGENTS.md 未注入"
rm -rf "$SANDBOX"

# 6. 其余安装分支沙箱实测（cursor / aider / project）
REPO=$(pwd)
S2=$(mktemp -d)
( cd "$S2" && HOME="$S2" bash "$REPO/install.sh" --cursor > /dev/null && HOME="$S2" bash "$REPO/install.sh" --cursor > /dev/null )
[ "$(grep -c 'token-saver:begin' "$S2/.cursorrules")" = "1" ] || fail "cursorrules 注入不幂等"
HOME="$S2" bash install.sh --aider > /dev/null
[ -f "$S2/.token-saver/CONVENTIONS.md" ] || fail "aider 规范未安装"
grep -q "CONVENTIONS.md" "$S2/.aider.conf.yml" || fail "aider 配置未创建"
HOME="$S2" bash install.sh --project "$S2" > /dev/null
grep -q "token-saver:begin" "$S2/CLAUDE.md" || fail "project 注入失败"
rm -rf "$S2"

# 7. token 计数器
out=$(printf 'hello world 你好' | node bin/token-count.mjs)
echo "$out" | grep -q "est. tokens: 5" || fail "token 估算异常: [$out]"

echo "✅ 全部自检通过"
