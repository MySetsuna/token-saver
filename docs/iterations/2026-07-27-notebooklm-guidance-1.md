# NotebookLM guidance 1 + 对抗评审

## Maker 原文

NotebookLM 对两份临时来源（《AI 编程会话成本与效率分析》+ iteration 1 后 `PROJECT-STATE`）给出：

1. 它把 TS-1..TS-5 错配为 squeez、repomix、缓存守护、人格、Ponytail；
2. 宣称 `pack-repo` 与多语言人格模板缺失；
3. 建议 `token-baseline.mjs`、`--max-floor`、分拆人格模板、`pack-diff.sh`；
4. 同时承认：虚拟价格不算实测节省，reasoning 不证明代码质量，请求 usage 不可得时须返回 `null`。

其建议合同原貌：

| 建议 | 文件落点 | 所称验收 |
|---|---|---|
| token baseline | `bin/token-baseline.mjs` | candidate input 缩减 10% 则 0 |
| floor warning | `bin/token-usage.mjs` | `--max-floor` 越界给 `/compact` |
| persona templates | `config/persona-wenyan.md`, `config/persona-caveman.md` | 安装后包含人格约束 |
| diff pack | `bin/pack-diff.sh` | 只打改动/关联文件，宣称降 50% |

## Checker：代码事实核对

| Maker 断言 | 代码事实 | 结论 |
|---|---|---|
| TS-1..TS-5 是五层旧能力 | `开放愿景清单` 实为会话账本、比例陷阱、预算闸、产出证据、交付对账 | 引用错配 |
| `pack-repo` 缺失 | `bin/pack-repo.sh`、`package.json#pack:repo` 已存在 | 事实错误 |
| 人格模板缺失 | `config/claude-md.template` 已同时含中文微言、英文 Caveman，并由各平台共用 | 事实错误 |
| Ponytail 缺“模块” | Ponytail 本来就是行为规范层，刻意不做 runtime 拦截器 | 层次错配 |
| 需新 `token-baseline` | `bin/usage-delta.mjs` 已比较两快照 | 重复实现 |
| 需 `--max-floor` | iteration 1 已有 Context Floor proxy、input/cache-read 请求峰值与预算 exit 1 | 重复实现 |
| `pack-diff` 保证降 50% | 改动文件不等于依赖闭包；无仓库/任务基线不能承诺比例 | 验收不可判且误导 |

## Reframe 表

| 原建议 | 更高价值可测切片 | 验收信号 | 判定 |
|---|---|---|---|
| 新造 `token-baseline` | 沿现有 `usage-delta` 升为多样本实验比较：median/p95、质量闸与回归预算 | 固定多运行 fixtures；JSON schema；0/1/2 退出码 | reframed 采纳，入 iteration 2 |
| `--max-floor` 实时预警 | 保留 iteration 1 的显式预算；日志只支持事后/增量观测，不冒充实时代理 | 已有 known/unavailable tests | 已实现，不重复 |
| 分拆人格模板 | 保持单一共享模板，减少漂移与缓存前缀分叉 | 安装幂等与模板 tests | non-goal + 既有替代 |
| `pack-diff` + 50% | 继续 `git diff/status → CodeGraph → rg → 精确行段`；只有需全景才 repomix | 不新增不诚实比例承诺 | non-goal + 既有替代 |

## 裁决

- iteration 1：通过；对话源的 TS-1..TS-5 已实现并验收。
- 下一轮只采纳“多样本、质量感知 usage 回归实验”升值切片；其余为已实现、重复或违 SSOT。
- Maker 对证据边界的三条提醒保留：虚拟价格非实测、reasoning 非质量、不可得请求峰值必须 `null`。
