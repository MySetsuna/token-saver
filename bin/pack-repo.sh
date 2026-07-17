#!/usr/bin/env bash
# pack-repo — L2 代码库瘦身测量化：repomix 打包并实测打包前后 token
# 用法: bash bin/pack-repo.sh [--compress] [输出文件]     默认 repomix-output.xml
#   --compress  额外跑一次 repomix --compress（tree-sitter 抽签名、弃函数体），与普通打包对比
# 注：repomix 是唯一真外部工具，用时 npx 拉，不入 package.json 依赖。首次需联网。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

COMPARE=0
if [ "${1:-}" = "--compress" ]; then COMPARE=1; shift; fi
OUT="${1:-repomix-output.xml}"

command -v node >/dev/null || { echo "❌ 需要 node"; exit 1; }

tok() { node bin/token-count.mjs "$1" | sed 's/.*est\. tokens: //'; }
pct() { [ "$1" -gt 0 ] && echo "$(( ($1 - $2) * 100 / $1 ))" || echo 0; }

# 打包前：git 跟踪的文本源码合计 token（跳过二进制/锁文件）
# ponytail: 直接把文件列表喂给 token-count，超大仓（数万文件）会撞 ARG_MAX，届时改 xargs 分批
mapfile -t FILES < <(git ls-files | grep -viE '\.(png|jpe?g|gif|ico|svg|pdf|zip|gz|woff2?|ttf|eot|lock)$')
[ "${#FILES[@]}" -gt 0 ] || { echo "❌ 无跟踪文件（是 git 仓库吗？）"; exit 1; }
before=$(node bin/token-count.mjs "${FILES[@]}" | sed 's/.*est\. tokens: //')

echo "▶ 打包中（npx -y repomix，首次需联网）..."
npx -y repomix --remove-comments --remove-empty-lines -o "$OUT" >/dev/null 2>&1 \
  || { echo "❌ repomix 打包失败（检查网络或 repomix 可用性）"; exit 1; }
plain=$(tok "$OUT")

echo "L2 代码库瘦身实测"
printf '  %-22s %8s token（%d 个文件）\n' "打包前源码合计" "$before" "${#FILES[@]}"
printf '  %-22s %8s token  节省 %s%%  → %s\n' "普通打包(剥注释/空行)" "$plain" "$(pct "$before" "$plain")" "$OUT"

if [ "$COMPARE" = 1 ]; then
  COUT="${OUT%.*}-compressed.${OUT##*.}"
  if npx -y repomix --compress -o "$COUT" >/dev/null 2>&1; then
    comp=$(tok "$COUT")
    printf '  %-22s %8s token  节省 %s%%  → %s\n' "抽签名打包(--compress)" "$comp" "$(pct "$before" "$comp")" "$COUT"
  else
    echo "  ⚠️  --compress 模式失败/不可用（可能缺 tree-sitter 语法，或此仓无可抽取的代码结构）"
  fi
fi
