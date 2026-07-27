# CONTRACT iteration 2：多样本、质量感知的 Usage 回归实验

## 目标

把 `usage-delta` 的“两份总量相减”升为可复现实验闸：同任务多次 baseline / candidate，比较 median 与 p95，同时把外部质量结果纳入，不以一次幸运样本承诺收益。

## 工作量与范围（约 2 工程日）

### G1. 快照 schema 与兼容读取

- `bin/usage-delta.mjs` 兼容 v1 原始快照及 iteration 1 的 `accountedInput`、metrics、evidence。
- 明确旧快照无法确定 provider 口径时的 `unknown`，不偷偷重算。

验收：v1/v2/缺字段/非法 JSON fixtures；参数错 exit 2。

### G2. 多样本实验清单

- 新增 `bin/usage-experiment.mjs`，读取一个本地 JSON manifest：baseline/candidate 各含 3+ 快照与可选质量退出码。
- 不读取对话正文，不扫描网络，不内置价格。

验收：3×2 固定 fixtures；样本不足 fail closed。

### G3. 稳健统计

- 对 accounted input、cache read/write、output、total 计算 median、p95 与相对变化。
- 比例指标用“先聚合物理量再算比例”，禁止直接平均百分比。

验收：乱序、极端值、零分母 fixture 数学断言。

### G4. 质量感知回归预算

- manifest 支持 token 上限、回归百分比与全部 quality gate 必须通过。
- 只有 token 闸与质量闸同时通过才 exit 0；回归/质量失败 exit 1；证据不可得亦 exit 1。

验收：pass/token-regression/quality-fail/unavailable 四路径。

### G5. 机器/人类输出

- `--json` 给稳定 schema/version、样本数、统计量、violations。
- 文本输出先结论，再列首因；不写“省钱 X%”因果语句，只写候选相对基线的观测变化。

验收：JSON snapshot 与关键文本断言。

### G6. 安装、文档与端到端测试

- `install.sh` 安装新 CLI 与 Windows `.cmd` 垫片。
- README 给一次同任务实验流程；CHANGELOG 与模板更新。
- `pnpm test` 覆盖安装、schema、统计、退出码。

## 非目标

- 不自动跑 Agent 任务；manifest 只消费已生成 usage 快照。
- 不做实时代理、自动 compact、模型价格抓取。
- 不用 changed lines 或 reasoning ratio 代替质量闸。
- 不承诺固定节省百分比。

## 里程碑

`schema/fixtures → statistics → policy exits → CLI output → install/docs`

## 完成闸

```text
pnpm test
node --check bin/usage-delta.mjs
node --check bin/usage-experiment.mjs
git diff --check
codegraph sync
```
