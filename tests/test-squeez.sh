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

# 3.1 扩展错误信号（TypeError / npm ERR）截断后仍保留
out=$( { seq 1 500; echo "TypeError: x is not a function"; seq 501 1000; } | bash $S )
echo "$out" | grep -q "TypeError: x is not a function" || fail "TypeError 行丢失"
out=$( { seq 1 500; echo "npm ERR! code ERESOLVE"; seq 501 1000; } | bash $S )
echo "$out" | grep -q "npm ERR! code ERESOLVE" || fail "npm ERR 行丢失"

# 3.2 SQUEEZ_JSON_MAX：超长单行 JSON 截断；默认关不改写
long_json=$(printf '{'; for i in $(seq 1 80); do printf '"k%d":%d,' "$i" "$i"; done; printf '"z":1}')
out=$(printf '%s\n' "$long_json" | SQUEEZ_JSON_MAX=40 bash $S)
echo "$out" | grep -q 'json truncated' || fail "JSON 截断未生效: [$out]"
out=$(printf '%s\n' "$long_json" | bash $S)
echo "$out" | grep -q 'json truncated' && fail "默认不应截断 JSON"
echo "$out" | grep -q '"z":1}' || fail "默认 JSON 应原样"

# 4. 短输出原样通过
out=$(printf 'a\nb\nc\n' | bash $S)
[ "$out" = "$(printf 'a\nb\nc')" ] || fail "短输出被改动"

# 5. install.sh --claude-code 在沙箱 HOME 中幂等
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.claude"
cat > "$SANDBOX/.claude/settings.json" <<'JSON'
{"model":"opus","hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"bash -c \"cat ~/.claude/token-saver-reminder.md\""}]}],"PreToolUse":[{"matcher":"Read","hooks":[{"type":"command","command":"keep-me"}]},{"matcher":"Write|Edit","hooks":[{"type":"command","command":"node token-saver-cache-hook.mjs"}]}]}}
JSON
HOME="$SANDBOX" bash install.sh --all > /dev/null
HOME="$SANDBOX" bash install.sh --all > /dev/null   # 第二次，验证幂等
[ -x "$SANDBOX/.local/bin/squeez" ] || fail "squeez 未安装"
[ -x "$SANDBOX/.local/bin/token-usage" ] || fail "token-usage 未安装"
[ -x "$SANDBOX/.local/bin/prompt-prefix-check" ] || fail "prompt-prefix-check 未安装"
[ -x "$SANDBOX/.local/bin/cache-lint" ] || fail "cache-lint 未安装"
[ -x "$SANDBOX/.local/bin/usage-delta" ] || fail "usage-delta 未安装"
if [ "${OS:-}" = "Windows_NT" ] || [ -n "${MSYSTEM:-}" ]; then
    [ -f "$SANDBOX/.local/bin/squeez.cmd" ] || fail "Windows 垫片未安装"
    [ -f "$SANDBOX/.local/bin/token-usage.cmd" ] || fail "token-usage Windows 垫片未安装"
    [ -f "$SANDBOX/.local/bin/prompt-prefix-check.cmd" ] || fail "prompt-prefix-check Windows 垫片未安装"
    [ -f "$SANDBOX/.local/bin/cache-lint.cmd" ] || fail "cache-lint Windows 垫片未安装"
fi
[ "$(grep -c 'token-saver:begin' "$SANDBOX/.claude/CLAUDE.md")" = "1" ] || fail "CLAUDE.md 注入不幂等"
grep -q "token-usage" "$SANDBOX/.claude/CLAUDE.md" || fail "真实 usage 计量规范未注入"
grep -q "git diff/status.*CodeGraph.*rg" "$SANDBOX/.claude/CLAUDE.md" || fail "检索优先规范未注入"
grep -q '默认 `terse`' "$SANDBOX/.claude/CLAUDE.md" || fail "terse 输出模式未注入"
grep -q '`audit`' "$SANDBOX/.claude/CLAUDE.md" || fail "audit 输出模式未注入"
grep -q "prompt-prefix-check" "$SANDBOX/.claude/CLAUDE.md" || fail "确定性缓存检查规范未注入"
grep -q "Ponytail" "$SANDBOX/.claude/CLAUDE.md" || fail "Ponytail 协议未默认注入"
# 注入模板本身须通过 cache-lint（无缓存杀手字面）
node bin/cache-lint.mjs "$SANDBOX/.claude/CLAUDE.md" || fail "注入后 CLAUDE.md 含缓存杀手"
[ -f "$SANDBOX/.claude/token-saver-reminder.md" ] || fail "提醒文件未安装"
[ -f "$SANDBOX/.claude/token-saver-reminder-hook.mjs" ] || fail "提醒 hook 脚本未安装"
[ "$(wc -l < "$SANDBOX/.claude/token-saver-reminder.md")" -eq 1 ] || fail "抗漂移提醒未缩成单行"
[ "$(wc -c < "$SANDBOX/.claude/token-saver-reminder.md")" -lt 240 ] || fail "抗漂移提醒仍过长"
[ ! -f "$SANDBOX/.claude/token-saver-cache-hook.mjs" ] || fail "旧 cache-lint hook 文件未移除"
node -e '
    const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (s.model !== "opus") throw "用户原设置被吞";
    const arr = s.hooks.UserPromptSubmit;
    const n = JSON.stringify(arr).split("token-saver-reminder").length - 1;
    if (n !== 1) throw "UserPromptSubmit 注入不幂等: " + n;
    if (JSON.stringify(arr).includes("bash -c")) throw "UserPromptSubmit 不应依赖 bash";
    if (JSON.stringify(arr).includes("node -e")) throw "UserPromptSubmit 不应含脆弱内联脚本";
    if (!JSON.stringify(arr).includes("token-saver-reminder-hook.mjs")) throw "UserPromptSubmit 未指向独立 hook 脚本";
    const pre = s.hooks.PreToolUse || [];
    if (JSON.stringify(pre).includes("token-saver-cache-hook")) throw "旧缓存 hook 未迁移";
    if (!JSON.stringify(pre).includes("keep-me")) throw "第三方 PreToolUse hook 被误删";
' "$SANDBOX/.claude/settings.json" || fail "settings.json hook 校验失败"
h2=$(md5sum "$SANDBOX/.claude/CLAUDE.md")
HOME="$SANDBOX" bash install.sh --all > /dev/null   # 第三次，验证字节级幂等
[ "$h2" = "$(md5sum "$SANDBOX/.claude/CLAUDE.md")" ] || fail "注入非字节级幂等"
grep -q "token-saver:begin" "$SANDBOX/.codex/AGENTS.md" || fail "codex AGENTS.md 未注入"
rm -rf "$SANDBOX"

# 6. 其余安装分支沙箱实测（ridgecode / cursor / aider / project）
REPO=$(pwd)
S2=$(mktemp -d)
HOME="$S2" bash install.sh --ridgecode > /dev/null
HOME="$S2" bash install.sh --ridgecode > /dev/null   # 幂等
[ "$(grep -c 'token-saver:begin' "$S2/.ridge/AGENTS.md")" = "1" ] || fail "ridgecode 注入不幂等"
grep -q "Ponytail" "$S2/.ridge/AGENTS.md" || fail "ridgecode 规范缺 Ponytail"
grep -q "微言大义" "$S2/.ridge/AGENTS.md" || fail "ridgecode 须与主模板一致（含文言）"
HOME="$S2" bash install.sh --grok > /dev/null
HOME="$S2" bash install.sh --grok > /dev/null
[ "$(grep -c 'token-saver:begin' "$S2/.grok/AGENTS.md")" = "1" ] || fail "grok 注入不幂等"
grep -q "Ponytail" "$S2/.grok/AGENTS.md" || fail "grok 规范缺 Ponytail"
grep -q "微言大义" "$S2/.grok/AGENTS.md" || fail "grok 须含文言协议"
( cd "$S2" && HOME="$S2" bash "$REPO/install.sh" --cursor > /dev/null && HOME="$S2" bash "$REPO/install.sh" --cursor > /dev/null )
[ "$(grep -c 'token-saver:begin' "$S2/.cursorrules")" = "1" ] || fail "cursorrules 注入不幂等"
grep -q "微言大义" "$S2/.cursorrules" || fail "cursor 须与主模板一致"
HOME="$S2" bash install.sh --aider > /dev/null
[ -f "$S2/.token-saver/CONVENTIONS.md" ] || fail "aider 规范未安装"
grep -q "微言大义" "$S2/.token-saver/CONVENTIONS.md" || fail "aider 须与主模板一致"
grep -q "CONVENTIONS.md" "$S2/.aider.conf.yml" || fail "aider 配置未创建"
HOME="$S2" bash install.sh --project "$S2" > /dev/null
grep -q "token-saver:begin" "$S2/CLAUDE.md" || fail "project 注入失败"
rm -rf "$S2"

# 7. token 计数器
out=$(printf 'hello world 你好' | node bin/token-count.mjs)
echo "$out" | grep -q "est. tokens: 5" || fail "token 估算异常: [$out]"

# 7.1 Windows 原生入口存在，默认转发到 --all
grep -q "ValueFromRemainingArguments" install.ps1 || fail "PowerShell 入口未支持透传参数"
grep -q '\$InstallArgs = @("--all")' install.ps1 || fail "PowerShell 入口未默认 all"

# 8. 服务端 usage 实测聚合：Claude 按请求累加；Codex 每会话只取最终累计值
TMP9=$(mktemp -d)
cat > "$TMP9/claude.jsonl" <<'JSON'
{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_creation_input_tokens":3,"cache_read_input_tokens":4,"output_tokens":5}}}
{"type":"assistant","message":{"usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":6,"output_tokens":7}}}
JSON
cat > "$TMP9/codex.jsonl" <<'JSON'
{"type":"event_msg","payload":{"info":{"total_token_usage":{"input_tokens":100,"cached_input_tokens":40,"cache_write_input_tokens":10,"output_tokens":20,"reasoning_output_tokens":5,"total_tokens":120}}}}
{"type":"event_msg","payload":{"info":{"total_token_usage":{"input_tokens":150,"cached_input_tokens":60,"cache_write_input_tokens":15,"output_tokens":30,"reasoning_output_tokens":8,"total_tokens":180}}}}
JSON
usage=$(node bin/token-usage.mjs --json "$TMP9")
node -e '
  const u=JSON.parse(process.argv[1]);
  if (u.input !== 162 || u.cacheRead !== 70 || u.cacheWrite !== 18 || u.output !== 42 || u.total !== 217)
    throw new Error("usage 聚合错误: " + JSON.stringify(u));
' "$usage" || fail "token-usage 聚合失败"

# 9. prompt 前缀：允许稳定动态尾；strict 要求全同
printf 'static\none\n' > "$TMP9/a"
printf 'static\ntwo\n' > "$TMP9/b"
node bin/prompt-prefix-check.mjs --min-prefix 7 "$TMP9/a" "$TMP9/b" >/dev/null || fail "稳定前缀阈值误判"
if node bin/prompt-prefix-check.mjs --min-prefix 8 "$TMP9/a" "$TMP9/b" >/dev/null 2>&1; then fail "不稳定前缀未检出"; fi
if node bin/prompt-prefix-check.mjs --strict "$TMP9/a" "$TMP9/b" >/dev/null 2>&1; then fail "strict 未检出差异"; fi
node bin/prompt-prefix-check.mjs --strict "$TMP9/a" "$TMP9/a" >/dev/null || fail "strict 误报相同快照"

# 10. cache-lint：模板干净 + 正负样本 + fix 预览/写回/备份
for tmpl in config/claude-md.template config/reminder.md; do
  node bin/cache-lint.mjs "$tmpl" || fail "模板含缓存杀手: $tmpl"
done
printf 'ok line\nToday is 2026-07-24\nid %s\n' "550e8400-e29b-41d4-a716-446655440000" > "$TMP9/dirty.md"
if node bin/cache-lint.mjs "$TMP9/dirty.md" >/dev/null 2>&1; then fail "cache-lint 未检出杀手"; fi
fixed=$(node bin/cache-lint.mjs --fix "$TMP9/dirty.md")
echo "$fixed" | grep -q '⟨removed⟩' || fail "cache-lint --fix 未替换"
echo "$fixed" | grep -q '2026-07-24' && fail "cache-lint --fix 仍含日期"
node bin/cache-lint.mjs --fix --write "$TMP9/dirty.md" >/dev/null
[ -f "$TMP9/dirty.md.cache-lint.bak" ] || fail "cache-lint 未写备份"
node bin/cache-lint.mjs "$TMP9/dirty.md" || fail "fix 写回后仍脏"

# 11. usage-delta：两次快照差
printf '{"input":100,"cacheRead":10,"cacheWrite":5,"output":20,"total":135}\n' > "$TMP9/u1.json"
printf '{"input":80,"cacheRead":12,"cacheWrite":4,"output":15,"total":111}\n' > "$TMP9/u2.json"
delta=$(node bin/usage-delta.mjs "$TMP9/u1.json" "$TMP9/u2.json")
echo "$delta" | grep -q $'total\t135\t111\t-24' || fail "usage-delta 差值错误: [$delta]"

# 12. --uninstall 恢复备份并移除 reminder
S3=$(mktemp -d)
mkdir -p "$S3/.claude"
echo "ORIG_CLAUDE" > "$S3/.claude/CLAUDE.md"
printf '%s\n' '{"model":"opus"}' > "$S3/.claude/settings.json"
HOME="$S3" bash install.sh --claude-code > /dev/null
[ -f "$S3/.claude/CLAUDE.md.token-saver.bak" ] || fail "安装未留 CLAUDE 备份"
HOME="$S3" bash install.sh --uninstall > /dev/null
[ "$(cat "$S3/.claude/CLAUDE.md")" = "ORIG_CLAUDE" ] || fail "uninstall 未恢复 CLAUDE.md"
[ ! -f "$S3/.claude/token-saver-reminder.md" ] || fail "uninstall 未删 reminder"
rm -rf "$S3" "$TMP9"

echo "✅ 全部自检通过"
