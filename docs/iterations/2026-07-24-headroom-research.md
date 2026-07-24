# Headroom 调研归档 · 2026-07-24

- 上游：https://github.com/headroomlabs-ai/headroom（Apache-2.0）
- 笔记本源：`ec000a72-6521-426d-9ea3-bbf954a6ebee`
- 文档：https://headroom-docs.vercel.app/docs
- 对照对象：本仓 token-saver 五层（squeez / repomix / 缓存锚定 / 语义预算 / Ponytail）
- 证据：`nlm source content`、GitHub README、architecture / how-compression-works / cache-optimization 文档页

## 1. Headroom 核心能力与接入方式

**定位**：本地优先的 **context compression 层**——在消息到达 LLM 前压缩工具输出、日志、RAG、文件与部分历史。

| 接入 | 说明 |
|---|---|
| Library | Python/TS `compress(messages)` |
| Proxy | `headroom proxy --port 8787`，改 base URL |
| Agent wrap | `headroom wrap claude\|codex\|…` 一键代理会话 |
| MCP | `headroom_compress` / `headroom_retrieve` / `headroom_stats` |

**管线（摘要）**：

1. **CacheAligner** — 把 system 中日期/会话等动态段挪到尾部，稳定前缀以利 provider KV cache
2. **ContentRouter** — 按类型路由：SmartCrusher(JSON)、CodeCompressor(AST)、Log/Search/Diff/Text、可选 Kompress ML
3. **CCR** — 压缩可逆：原文入本地缓存，模型可 `retrieve`
4. **Output shaper**（可选）— 输出端 terse + 工具回合降 thinking effort
5. **Memory / learn** — 跨 agent 记忆；失败会话挖掘写回 `CLAUDE.md`/`AGENTS.md`

自称量级：JSON 工具输出 60–95%；coding agent 整体约 15–20%。上游 README 明确推荐 **Ponytail** 作输出侧伴侣。

## 2. 与 token-saver 五层：重叠与差异

| 维度 | Headroom | token-saver | 关系 |
|---|---|---|---|
| 产品形态 | 运行时库/代理/MCP | 安装脚本 + 规范模板 + 轻 CLI | **正交层** |
| 终端日志 | LogCompressor；可挂 RTK/lean-ctx | `squeez`（错误行永留） | 重叠域，实现不同 |
| 代码上下文 | AST CodeCompressor | `repomix`/`pack-repo` | 重叠域 |
| 缓存 | 运行时 CacheAligner + provider 标记 | 安装时静态前置规范 + `prompt-prefix-check` | 同目标不同钩子 |
| 输出 token | verbosity steering / effort routing | L4 语义预算 + 文言/Caveman | 重叠域，本仓更深语言路由 |
| 少写码 | 推荐外部 Ponytail | L5 Ponytail **已内置** | 本仓已覆盖 |
| JSON 工具输出粉碎 | SmartCrusher 主收益 | 无结构感知 JSON 采样 | **Headroom 独有（代理向）** |
| 可逆压缩 CCR | 有 | 无 | Headroom 独有 |
| 跨 agent 记忆 / learn | 有 | 无 | Headroom 独有，非本仓主线 |
| 真实 usage 计量 | savings/perf/dashboard | `token-usage` 读服务端 JSONL | 各有计量路径 |
| 零依赖/轻装 | Python+可选 ML/ONNX 重 | bash/node 标准库为主 | 本仓刻意轻 |

**一句话**：Headroom = **运行时吞一切上下文再吐**；token-saver = **装一次就把人与工具的行为规范钉住**。上游自己把 Ponytail 当伴侣，侧面印证输出/建造层不是它的核心交付。

## 3. 候选采纳项与判定

硬门槛（goal）：与本仓**不重叠** + **可确定性验收** + 不违反 non-goals（不 fork 成代理产品）。

| # | 候选 | 判定 | 理由 |
|---|---|---|---|
| A | 整包接入 Headroom proxy / wrap | **驳回** | 把 token-saver 改成/捆绑代理产品；non-goal 明文禁止；重依赖与本仓「安装即用、零重依赖」冲突 |
| B | 移植 SmartCrusher（JSON 统计采样） | **驳回** | 主收益在 runtime 工具 JSON；本仓交付面是 shell 管道与规范注入。重写等于半套 Headroom，维护税不可接受 |
| C | 移植 CacheAligner 运行时搬动态段 | **驳回** | L3 已用「静态在前、动态在后」+ `prompt-prefix-check`；运行时改写 message 需代理位。理念已吸收，无需再造 |
| D | CCR 可逆压缩 | **驳回** | 依赖本地压缩缓存与 retrieve 工具链，超范围 |
| E | Output shaper / effort routing | **驳回** | L4 语义预算 + 语言路由已覆盖「少说」；effort 属代理改请求字段 |
| F | headroom learn 失败挖掘 | **驳回** | 会话 JSONL 挖掘写回规则，另产品；与本仓计量路径不同，无最小可测切片不引入重栈 |
| G | 跨 agent memory | **驳回** | 非 token 节省主交付 |
| H | MCP `compress` 工具 | **驳回** | 同代理系 |
| I | 文档写「可与 Headroom 互补外挂」 | **驳回（本轮不进产品 diff）** | 有认知价值但无确定性验收收益；非功能采纳。若日后写 README 一句外链，单独文档 PR，不绑迭代合同 |
| J | 增强 squeez 做弱 JSON 折叠 | **驳回** | 易损正确性（squeez 承诺错误行语境）；与 SmartCrusher 不可比；YAGNI |

## 4. 总否定结论

**本轮无值得采纳进 token-saver 产品代码的 Headroom 能力。**

依据：

1. **定位正交**：本仓是规范/安装/轻工具；Headroom 是本地 LLM 代理压缩层。goal non-goals 禁止 fork/变代理产品。
2. **重叠面已覆盖**：终端压、代码瘦身、缓存前缀稳定、输出精简、Ponytail——本仓均有对应层；Headroom README 甚至推荐 Ponytail 作伴侣。
3. **差异面均绑代理重栈**：SmartCrusher / CCR / wrap / memory / learn 无法在「最小可测 diff + 现有 `pnpm test`」内诚实落地，而不背叛轻量交付物。
4. **取长方式**：用户若工具 JSON/RAG 极重，**并列安装 Headroom**（`headroom wrap`）即可，不必改 token-saver 源码。取长 = 架构认知与可选外挂，不是合仓。

## 5. 对本仓的负面清单（勿做）

- 勿引入 `headroom-ai` 为硬依赖
- 勿在 install 里静默 `headroom wrap`
- 勿复制 SmartCrusher 半吊子 JSON 采样进 `squeez`
- 勿用 Headroom 宣传数字替换本仓 `pnpm bench` 诚实计量

## 6. 若未来重开的触发条件（非本轮合同）

仅当**同时**满足再开 CONTRACT：

1. 用户明确要 runtime 工具输出结构化压缩，且接受代理或显式可选依赖；
2. 有可退出码验收的最小切片（例：给定 fixture JSON → 压缩后 token-count 降幅与错误字段保留断言）；
3. 不破坏 squeez 错误行承诺与 install 幂等不变量。

否则保持本否定结论。
