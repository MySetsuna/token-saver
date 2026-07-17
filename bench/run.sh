#!/usr/bin/env bash
# bench — 直观量化 Token Saver 的节省效果（真实可跑、可复现、无需网络）
#   终端压缩（确定性）：squeez 对合成终端噪声，实测压缩前后 token
#   输出层（行为性）：同义的 白话vs文言 / 冗长英文vs caveman / 过度设计vs Ponytail 的 token 对比
#                    —— 属「潜在省耗」，真实节省取决模型是否遵从协议
# 用法: bash bench/run.sh          # 人读表格
#       bash bench/run.sh --md     # 输出 markdown（贴进 README 用）
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

tok() { node bin/token-count.mjs | sed 's/.*est\. tokens: //'; }
strtok() { printf '%s' "$1" | node bin/token-count.mjs | sed 's/.*est\. tokens: //'; }
pct() { [ "$1" -gt 0 ] && echo $(( ($1 - $2) * 100 / $1 )) || echo 0; }

# ============ 终端压缩（确定性）============
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

tot_raw=$(( RAW[0] + RAW[1] + RAW[2] ))
tot_sq=$((  SQ[0]  + SQ[1]  + SQ[2]  ))

# ============ 输出层（行为性，潜在省耗）============
# 文言：同一技术解释，白话 vs 微言大义（多例取均）
wy_raw=0; wy_out=0
add_wy() { local r o; r=$(strtok "$1"); o=$(strtok "$2"); wy_raw=$((wy_raw+r)); wy_out=$((wy_out+o)); }
add_wy 'React 组件每次渲染都会重新创建 props 里对象的引用，导致子组件即使数据没有变化也会跟着重新渲染，用 useMemo 把这个对象包裹起来就可以避免这个问题。' \
       'React 每渲染新建 props 参照，子数据未变亦重绘；useMemo 包之免。'
add_wy 'JavaScript 是单线程的，通过事件循环协调异步任务。每执行完一个宏任务，就会清空所有微任务，然后再取下一个宏任务，所以 Promise 的回调总是先于 setTimeout 执行。' \
       'JS 单线程，事件循环谐异步。毕一宏任务尽清微任务乃取次宏，故 Promise 回调恒先 setTimeout。'
add_wy '数据库如果没有为查询条件里的列建立索引，查询时就必须全表扫描，逐行比对，数据量大的时候会非常慢；建立索引之后就能快速定位到目标行。' \
       '查询列无索引则全表扫描逐行比对，数据巨则极慢；建索引则速定其行。'
add_wy '如果直接在公共分支上使用 git rebase 修改已经推送的提交历史，会导致其他协作者的本地历史和远程产生分歧，引发混乱，所以只应在自己的私有分支上 rebase。' \
       '公共分支 rebase 改已推之史，则他人本地与远程歧而生乱；rebase 只宜于己私有分支。'

# caveman：冗长英文 vs caveman
cv_raw=0; cv_out=0
add_cv() { local r o; r=$(strtok "$1"); o=$(strtok "$2"); cv_raw=$((cv_raw+r)); cv_out=$((cv_out+o)); }
add_cv 'The component re-renders on every update because a new object reference is created for the props each time, so you should wrap it in useMemo to keep the reference stable.' \
       'New object ref each render. Wrap in useMemo. Ref stays stable.'
add_cv 'The request is failing because the authentication token has expired, so you need to refresh the token before retrying the request.' \
       'Token expired. Refresh token. Retry request.'
add_cv 'You are running out of memory because the loop keeps appending to the array without ever releasing the old references, so the heap grows unbounded.' \
       'Loop appends, never frees. Heap grows unbounded. Release old refs.'

# Ponytail：过度设计 vs 最小实现（示例，量的是代码本身）
py_verbose='interface Cache { get(k: string): string | undefined }
class LruCacheFactory { create(): Cache { return new MapCache() } }
class MapCache implements Cache { private m = new Map<string,string>(); get(k){ return this.m.get(k) } }
const cache = new LruCacheFactory().create()'
py_lazy='const cache = new Map()'
py_raw=$(strtok "$py_verbose"); py_out=$(strtok "$py_lazy")

if [ "${1:-}" = "--md" ]; then
  echo "**终端压缩（确定性，squeez 实测）**"
  echo ""
  echo "| 场景 | 原始 Token | 优化后 Token | 节省 |"
  echo "|------|-----------:|-------------:|-----:|"
  for i in 0 1 2; do
    echo "| ${NAME[$i]} | ${RAW[$i]} | ${SQ[$i]} | **$(pct ${RAW[$i]} ${SQ[$i]})%** |"
  done
  echo "| **终端三项合计** | **$tot_raw** | **$tot_sq** | **$(pct $tot_raw $tot_sq)%** |"
  echo ""
  echo "**输出层（行为性·潜在省耗，取决模型遵从协议）**"
  echo ""
  echo "| 协议 | 原始 Token | 优化后 Token | 节省 |"
  echo "|------|-----------:|-------------:|-----:|"
  echo "| 微言大义·文言（4 例合计） | $wy_raw | $wy_out | **$(pct $wy_raw $wy_out)%** |"
  echo "| Caveman（3 例合计） | $cv_raw | $cv_out | **$(pct $cv_raw $cv_out)%** |"
  echo "| Ponytail 建造精简（示例） | $py_raw | $py_out | **$(pct $py_raw $py_out)%** |"
else
  echo "【终端压缩·确定性】squeez 实测"
  printf '%-16s %10s %12s %8s\n' 场景 原始Token 优化后 节省
  for i in 0 1 2; do
    printf '%-16s %10s %12s %7s%%\n' "${NAME[$i]}" "${RAW[$i]}" "${SQ[$i]}" "$(pct ${RAW[$i]} ${SQ[$i]})"
  done
  printf '%-16s %10s %12s %7s%%\n' "终端合计" "$tot_raw" "$tot_sq" "$(pct $tot_raw $tot_sq)"
  echo "✅ 错误/警告行压缩后保留（承诺校验通过）"
  echo ""
  echo "【输出层·行为性】潜在省耗，取决模型遵从协议"
  printf '%-20s %10s %12s %8s\n' 协议 原始Token 优化后 节省
  printf '%-20s %10s %12s %7s%%\n' "文言(4例)"      "$wy_raw" "$wy_out" "$(pct $wy_raw $wy_out)"
  printf '%-20s %10s %12s %7s%%\n' "caveman(3例)"   "$cv_raw" "$cv_out" "$(pct $cv_raw $cv_out)"
  printf '%-20s %10s %12s %7s%%\n' "Ponytail(示例)" "$py_raw" "$py_out" "$(pct $py_raw $py_out)"
fi
