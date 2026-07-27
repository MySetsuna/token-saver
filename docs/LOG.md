# 工作日志（append-only，全局长期记忆）

> 每轮迭代结束后在**顶部**追加一条。仅本地归档，不上传 NotebookLM。

## 2026-07-27 iteration-1

- 做了什么：
  - 从《AI 编程会话成本与效率分析》提炼比例陷阱、Context Floor、预算止损与证据边界
  - `token-usage` 新增 provider-correct `accountedInput`、`--sessions`、逐请求平均/峰值
  - 新增四类预算 flags 与 0/1/2 退出码；请求证据不可得时 fail closed
  - 代码产出效率只接受显式 cost / changed-lines / quality-exit 三证
  - Claude/Codex fixtures、README、CHANGELOG、共享模板完成对账；`pnpm test` 全绿
- 下一步：iteration 2 多样本、质量感知 Usage 回归实验
- 触发的熔断：首测发现 Codex provider 被 spread 覆盖；一处修根因后全绿
- NotebookLM 对抗：
  - 驳回“pack-repo/人格模板缺失”等事实错误
  - 不重复造 token-baseline / max-floor
  - 将 baseline 建议升值为多样本 median/p95 + quality gate 合同

## 2026-07-24 iteration-optimize-1.3.0

- 做了什么：
  - 补 `bin/cache-lint.mjs` + 安装/测试（CLI only，不恢复 PreToolUse hook）
  - `bin/usage-delta.mjs`；`install.sh --uninstall`
  - squeez：扩展错误信号 + 可选 `SQUEEZ_JSON_MAX`
  - 压缩 `claude-md.template`；README/CLAUDE/CHANGELOG 诚实分层；LLMLingua 搁置
  - `pnpm test` 全绿
- 下一步：无强制；可选再压 cursorrules 或补 fixture 基准
- 触发的熔断：无
- 驳回：不内置 Headroom/LLMLingua；不恢复运行时缓存 hook

## 2026-07-24 init + headroom-research

- 做了什么：
  - `codegraph init -i`（5 文件 / 59 节点 / 83 边）
  - 建立 `docs/` 骨架（WORKFLOW / PROJECT-STATE / LOG / iterations）
  - NLM 笔记本「token节省之道」初始化：上传 `PROJECT-STATE`；分诊旧 8 源；规划类入 notes；旧源删除使来源恒 1
  - 深调研 Headroom（`ec000a72-…` + 上游 README/docs），对照本仓五层，归档 `docs/iterations/2026-07-24-headroom-research.md`
- 下一步：无产品代码采纳项；不写 CONTRACT 强推实现。日常迭代待有真实需求再开合同
- 触发的熔断：无
- 驳回了 NotebookLM 的哪些建议：本轮未 query 规划器；Headroom 侧代理/JSON 粉碎/CCR/wrap/memory/learn 等均驳回（见调研归档）
