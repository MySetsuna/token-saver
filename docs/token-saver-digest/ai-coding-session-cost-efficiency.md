# 《AI 编程会话成本与效率分析》分诊

> 来源仅作愿景与痛点素材；仓库事实以 CodeGraph、源码与测试为准。此报告只留本地，不上传 NotebookLM。

## 可保留的精华

1. **命中率有比例陷阱**：`cacheRead / (input + cacheRead + cacheWrite)` 很高，绝对 cache read 仍可因上下文底座巨大而昂贵。
2. **缓存写入须看绝对量**：长会话、缓存 TTL 或前缀变化均可能伴随大额 cache write；usage 可观测结果，不能仅凭日志断言根因。
3. **前缀稳定须确定性验证**：静态前置、动态后置；字节级公共前缀和缓存杀手字面可本地验。
4. **产出效率须接外部证据**：费用、wall/API time、diff 行数、测试结果可合看；reasoning/output token 不能等同代码行或质量。
5. **北极星是低成本完成正确任务**：非单追高命中率；须同时压绝对输入、缓存写、输出与无效回合。

## 来源中的夸大与错配

- “高 reasoning 比例导致一次成功”无确定性依据。
- “若无 token-saver 可省若干美元”多为假想价格与假想命中率，不是 A/B 实测。
- “95% 命中由 token-saver 导致”无法由单会话 usage 归因；缓存多由宿主与供应商实现。
- `cache-lint` 与 `usage-delta` 已存在，但来源把它们想象成 runtime 前缀改写与上下文追加器；源码并非如此。
- AST 骨架、Rust LangGraph、语义缓存、模型路由均未在本仓实现，且违反轻量工具链边界。
- 自动 `/compact` 或宿主会话截断缺稳定跨平台接口；只宜报告风险并给用户动作。

## Reframe 表

| 原建议 | 更高价值可测切片 | 验收信号 | 判定 |
|---|---|---|---|
| 只追 95%+ cache hit | 同报命中率与 cache read/write 绝对量、每请求负担 | 固定 fixture 数学断言 | reframed 采纳 |
| Context Floor Watcher | 从 JSONL 请求记录算逐会话平均/峰值，并支持显式阈值退出码 | 正常 fixture exit 0，超阈 fixture exit 1 | reframed 采纳 |
| Usage Recap 猜“高性价比” | 显式输入 cost、changed lines、quality signal；缺项即报 unknown | 缺证据不输出因果评价 | reframed 采纳 |
| runtime Cache-Lint 改写请求 | 复用离线 `cache-lint` + `prompt-prefix-check`，在报告中关联风险 | 既有工具 tests + 文档交叉引用 | non-goal + 既有替代 |
| 内置 AST 骨架器 | 架构问 CodeGraph，跨库打包用 repomix；会话报告只量 usage | 无新 runtime 依赖；现有闸全绿 | non-goal + 平台替代 |
| 自动 compact / 重启 | 阈值越界给明确动作，不控制宿主 | 输出建议可断言，退出码可脚本化 | reframed 采纳 |

## 开放愿景

| ID | 主题 | 状态 | 验收信号 |
|---|---|---|---|
| TS-1 | 会话级 usage 证据账本 | open | Claude/Codex fixtures 逐会话聚合准确 |
| TS-2 | 比例陷阱与 Context Floor 指标 | open | 公式有稳定 JSON 字段与边界测试 |
| TS-3 | Context Budget 显式闸 | open | flags 控阈，0/1/2 退出码稳定 |
| TS-4 | 代码产出效率证据边界 | open | 缺 cost/diff/quality 时明确 unknown |
| TS-5 | 安装、README、CHANGELOG 对账 | open | `pnpm test` 覆盖新 CLI 安装与文档承诺 |
