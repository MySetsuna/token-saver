# token-saver · 项目现状（PROJECT-STATE）

> **唯一**上传 NotebookLM 的项目来源。每轮覆盖式重写；历史只留 git 与 `docs/iterations/`。

## 项目是什么

Token Saver 是面向 Claude Code、Codex、Cursor、Aider、Grok 与 RidgeCode 的轻量 Token 治理工具链。核心交付物是幂等安装脚本、静态规范模板与零依赖 CLI，不是 LLM 网关或 Agent runtime。

五层主线：

1. `squeez` 压缩终端输出；
2. `repomix` / `pack-repo` 按需瘦代码库；
3. 静态前缀规范、`prompt-prefix-check` 与 `cache-lint` 守 Prompt Cache；
4. terse / normal / audit 语义预算与中文微言、英文 Caveman 路由；
5. Ponytail 约束代码增量，从源头少造代码。

金科玉律：代码块、命令、报错、路径等技术载荷 100% 原样；只压解释性文本。

## 已锁定决策

- 真实计量以 `token-usage --all` 读取服务端 usage 为准；`token-count` 仅粗估。
- 各层收益重叠，禁止相加；同任务须做 baseline / 优化后对照并另测正确率。
- 高缓存命中率不等于低成本：绝对缓存读量、缓存写量与每请求上下文底座同样关键。
- usage 数据只能证明用量、比例与时间等观测量；不能独自证明代码正确、一次成功或成本由 token-saver 节省。
- 维持安装脚本 + 轻 CLI 定位；不内置 LangGraph、语义向量缓存、LLMLingua、重型代理或模型路由。
- AST/架构事实优先复用 CodeGraph；跨库打包复用 repomix，不另造多语言 AST runtime。
- `cache-lint` 保持离线静态扫描，不恢复 PreToolUse 运行时改写。

## 当前架构（CodeGraph + 精确源码事实）

### 可解析模块

2026-07-27 三端 hook 对齐后 `codegraph status`：8 个 JavaScript 文件，113 nodes / 121 edges。

| 路径 | 当前职责 |
|---|---|
| `bin/token-usage.mjs` | Claude/Codex JSONL 聚合；provider-correct `accountedInput`；逐会话指标、请求峰值、预算闸与显式产出证据 |
| `bin/usage-delta.mjs` | 比较两份聚合快照的 input/cacheRead/cacheWrite/output/total 原始差值 |
| `bin/prompt-prefix-check.mjs` | 逐字节公共前缀、首差位置与 SHA-256；支持 strict / min-prefix 闸 |
| `bin/cache-lint.mjs` | 离线扫描日期、UUID、绝对家目录等前缀抖动字面 |
| `bin/token-count.mjs` | CJK 感知字符公式粗估 |
| `bin/run-bash.mjs` | Windows 经 Git Bash 执行 shell 测试 |
| `config/reminder-hook.mjs` | Claude Code / Codex 以 `additionalContext` 每回合注入一行抗漂移提醒 |
| `config/grok-drift-hook.mjs` | Grok `Stop` 阶段检测明确客套/续问漂移；仅命中时回灌一次 |

### Bash / 安装面

| 路径 | 当前职责 |
|---|---|
| `install.sh` / `install.ps1` | 幂等安装与模板注入；首次修改留 `*.token-saver.bak` |
| `bin/squeez` | ANSI 清理、重复折叠、头尾截断、错误行保留 |
| `tests/test-squeez.sh` | 跨工具确定性自检 |
| `bench/run.sh` | 本地相对基准；不冒充真实计费 |

### 关键调用路径

- `token-usage`: 参数校验 → roots → `collect` JSONL → `readUsage` → `normalizeUsage` → `metrics` → `enforce` 预算 → JSON/文本与 0/1/2 退出码。
- Claude：每条请求 usage 累加并更新峰值；Anthropic `accountedInput = input + cacheRead + cacheWrite`。
- Codex：以最终 `total_token_usage` 作会话总量；有 `last_token_usage` 才计算请求数/峰值；cached tokens 视 input 子集，不重复相加。
- `prompt-prefix-check`: 读两份 Buffer → 公共前缀逐字节比较 → stableBytes/hash → 退出码 0/1/2。
- 安装：平台分支 → `install_tools` → `install_squeez` + `install_node_tools`；模板经 `inject_block` 标记块整块替换；`--all` 对齐 Claude/Codex/Grok。
- 抗漂移：Claude/Codex `UserPromptSubmit` 注入相同单行摘要；Codex 首次经 `/hooks` 信任。Grok 被动事件 stdout 不进上下文，故以保守 `Stop` 检测纠偏，`stopHookActive` 时退出防循环。

## 能力对照

| 能力 | 状态 | 证据 / 差距 |
|---|---|---|
| 终端输出压缩 | 已实现 | `bin/squeez` + shell tests |
| 服务端 usage 聚合 | 已实现 | `bin/token-usage.mjs` |
| baseline / after 原始差值 | 已实现 | `bin/usage-delta.mjs` |
| 前缀字节稳定检查 | 已实现 | `bin/prompt-prefix-check.mjs` |
| 静态缓存杀手扫描 | 已实现 | `bin/cache-lint.mjs` |
| 会话级成本与效率复盘 | 已实现 | `--sessions`；文件名级账本、provider、原始绝对量、比例、Context Floor proxy、请求平均/峰值 |
| 代码产出成本证据边界 | 已实现 | `--cost-usd` / `--changed-lines` / `--quality-exit`；缺项即 `insufficient` |
| 上下文预算退出码 | 已实现 | cache hit 下限、cache write 总量、请求 input/cache read 峰值；报告默认 0，越界/不可得 1，参数错 2 |
| Claude/Codex/Grok 抗漂移 | 已实现（宿主适配） | 前二者每回合单行重锚；Grok 仅在明确输出漂移时低频纠偏 |
| runtime 代理 / 自动 compact | 非目标 | 只给动作建议，不劫持宿主会话 |

## 本轮状态

iteration 1 已完成《AI 编程会话成本与效率分析》的项目内可测切片：

- 把“高命中率即省钱”改写为 provider-correct 比例 + cache read/write 绝对量 + 请求峰值。
- 把“代码性价比很好”改写为显式 cost/diff/quality 三证；缺证据不评价。
- 把 runtime 自动干预改写为 opt-in 预算 flags 与稳定退出码；默认只报告。
- 将 AST、Rust LangGraph、语义缓存、模型路由判为本仓 non-goal，并给 CodeGraph/repomix/外部工具替代。
- README、CHANGELOG、注入模板与 shell fixtures 已对账。

## 确定性验证证据

```text
pnpm test → PASS（全部自检通过）
node --check bin/token-usage.mjs → PASS
git diff --check → PASS
node bin/token-usage.mjs --help → PASS
codegraph sync → Already up to date
codegraph status → 8 files / 113 nodes / 121 edges
本机三端安装冒烟 → 规则 marker 各 1；Token Saver hook 各 1；
                    Codex 输出 UserPromptSubmit，Grok 纠偏输出 Stop。
本机冒烟：197 JSONL / 183 usage 会话；97.84% cache hit；
          accounted input 2,414,669,749；平均 context floor proxy 172,300；
          accounted input 请求峰值 650,416。
```

本机冒烟仅证工具可读真实日志，不作为 token-saver 节省收益承诺。

## 差距与开放问题

- 对话源提炼出的愿景已对账：
  - TS-1 会话级 usage 证据账本：implemented；
  - TS-2 比例陷阱与 Context Floor 指标：implemented；
  - TS-3 Context Budget 显式闸：implemented；
  - TS-4 代码产出效率证据边界：implemented；
  - TS-5 安装、README、CHANGELOG 对账：implemented。
- 宿主未提供逐请求 usage 时，请求级指标保持 `null`；这是诚实边界，不以会话总量冒充峰值。
- NotebookLM 下一步建议经 checker 去除事实错配后，仅采纳升值项：把单次 `usage-delta` 升为多样本 median/p95 + quality gate 回归实验；合同见 `docs/iterations/CONTRACT-iteration-2.md`。

## 下一轮合同

iteration 2：多样本、质量感知 Usage 回归实验。主线为：

1. v1/v2 usage 快照兼容 schema；
2. baseline/candidate 3+ 样本 manifest；
3. accounted input/cache/output/total 的 median 与 p95；
4. token 回归预算 + 外部 quality gate 联合退出码；
5. 稳定 JSON/文本输出；
6. 安装、fixture、文档端到端闸。
