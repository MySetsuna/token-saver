#!/usr/bin/env bash
# bench — 直观量化 Token Saver 的节省效果（真实可跑、可复现、无需网络）
#   Layer 1 squeez：对合成的典型终端噪声，实测压缩前后 token
#   Layer 4 输出人格：同一技术解释的白话 vs 文言，对比字数（≈token）
# 用法: bash bench/run.sh          # 人读表格
#       bash bench/run.sh --md     # 输出 markdown（贴进 README 用）
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

tok() { node bin/token-count.mjs | sed 's/.*est\. tokens: //'; }
pct() { echo $(( ($1 - $2) * 100 / $1 )); }  # 节省百分比

gen_install() {
  for i in $(seq 1 80); do printf '\033[2K\r\033[36m⠋\033[0m resolving dependencies (%d/80)' "$i"; done
  printf '\n'
  for i in $(seq 1 300); do printf 'downloaded package-%03d@1.0.0\n' "$((i % 40))"; done
}
gen_build() {
  for i in $(seq 1 600); do printf '\033[32m[compile]\033[0m src/module_%03d.ts \xe2\x86\x92 dist/module_%03d.js\n' "$i" "$i"; done
  echo "WARNING: 'legacyFlag' is deprecated"
  echo "Build complete in 12.4s"
}
gen_test() {
  for i in $(seq 1 400); do printf '\033[32m\xe2\x9c\x93\033[0m test case %03d passed\n' "$i"; done
  echo "\xe2\x9c\x97 FAIL: edge_case_null returned undefined"
  for i in $(seq 401 700); do printf '\033[32m\xe2\x9c\x93\033[0m test case %03d passed\n' "$i"; done
}

declare -a NAME RAW SQ
row() {
  local raw sq
  raw=$($2 | tok)
  sq=$($2 | bash bin/squeez | tok)
  NAME+=("$1"); RAW+=("$raw"); SQ+=("$sq")
}
row "依赖安装日志" gen_install
row "构建编译日志" gen_build
row "测试运行输出" gen_test

gen_build | bash bin/squeez | grep -q "WARNING" || { echo "❌ warning 行丢失"; exit 1; }
gen_test  | bash bin/squeez | grep -q "FAIL"    || { echo "❌ FAIL 行丢失"; exit 1; }

plain='React 组件每次渲染都会重新创建 props 里对象的引用，导致子组件即使数据没有变化也会跟着重新渲染，用 useMemo 把这个对象包裹起来就可以避免这个问题。'
wenyan='React 组件每渲染皆新建 props 对象参照，子虽数据未变亦重绘；useMemo 包之则免。'
pr=$(printf '%s' "$plain"  | tok)
wy=$(printf '%s' "$wenyan" | tok)

tot_raw=$(( RAW[0] + RAW[1] + RAW[2] ))
tot_sq=$((  SQ[0]  + SQ[1]  + SQ[2]  ))

if [ "${1:-}" = "--md" ]; then
  echo "| 场景 | 原始 Token | 优化后 Token | 节省 |"
  echo "|------|-----------:|-------------:|-----:|"
  for i in 0 1 2; do
    echo "| ${NAME[$i]}（squeez） | ${RAW[$i]} | ${SQ[$i]} | **$(pct ${RAW[$i]} ${SQ[$i]})%** |"
  done
  echo "| 技术解释白话→文言（人格路由） | $pr | $wy | **$(pct $pr $wy)%** |"
  echo "| **终端三项合计** | **$tot_raw** | **$tot_sq** | **$(pct $tot_raw $tot_sq)%** |"
else
  printf '%-16s %10s %12s %8s\n' 场景 原始Token 优化后 节省
  for i in 0 1 2; do
    printf '%-16s %10s %12s %7s%%\n' "${NAME[$i]}" "${RAW[$i]}" "${SQ[$i]}" "$(pct ${RAW[$i]} ${SQ[$i]})"
  done
  printf '%-16s %10s %12s %7s%%\n' "白话→文言" "$pr" "$wy" "$(pct $pr $wy)"
  printf '%-16s %10s %12s %7s%%\n' "终端合计" "$tot_raw" "$tot_sq" "$(pct $tot_raw $tot_sq)"
  echo "✅ 错误/警告行压缩后保留（承诺校验通过）"
fi
