#!/usr/bin/env bash
# pack-repo — L2 代码库瘦身测量化：repomix 打包（剥注释/空行）并实测打包前后 token
# 用法: bash bin/pack-repo.sh [输出文件]      默认 repomix-output.xml
# 注：repomix 是唯一真外部工具，用时 npx 拉，不入 package.json 依赖。首次需联网。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
OUT="${1:-repomix-output.xml}"

command -v node >/dev/null || { echo "❌ 需要 node"; exit 1; }

# 打包前：git 跟踪的文本源码合计 token（跳过二进制/锁文件）
# ponytail: 直接把文件列表喂给 token-count，超大仓（数万文件）会撞 ARG_MAX，届时改 xargs 分批
mapfile -t FILES < <(git ls-files | grep -viE '\.(png|jpe?g|gif|ico|svg|pdf|zip|gz|woff2?|ttf|eot|lock)$')
[ "${#FILES[@]}" -gt 0 ] || { echo "❌ 无跟踪文件（是 git 仓库吗？）"; exit 1; }
before=$(node bin/token-count.mjs "${FILES[@]}" | sed 's/.*est\. tokens: //')

# 打包：repomix 剥注释与空行，输出单文件
echo "▶ 打包中（npx -y repomix，首次需联网）..."
npx -y repomix --remove-comments --remove-empty-lines -o "$OUT" >/dev/null 2>&1 \
  || { echo "❌ repomix 打包失败（检查网络或 repomix 可用性）"; exit 1; }

after=$(node bin/token-count.mjs "$OUT" | sed 's/.*est\. tokens: //')
echo "L2 代码库瘦身（repomix，剥注释+空行）"
printf '  打包前源码合计: %8s token（%d 个文件）\n' "$before" "${#FILES[@]}"
printf '  打包后单文件:   %8s token → %s\n' "$after" "$OUT"
if [ "$before" -gt 0 ]; then
  printf '  节省: %d%%\n' "$(( (before - after) * 100 / before ))"
fi
