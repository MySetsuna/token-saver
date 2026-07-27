# CONTRACT iteration 1：会话成本证据链与 Context Budget 闸

## 目标

用一条完整垂直切片兑现《AI 编程会话成本与效率分析》中可证实的愿景：从“只汇总 token”升级为“能发现 99% 命中比例陷阱、能脚本化止损、且不夸大代码质量”的轻量会话分析器。

## 范围

### G1. Provider-correct 输入口径

- `bin/token-usage.mjs` 区分 Anthropic 独立 cache 字段与 OpenAI/Codex 子集字段。
- 新增 `accountedInput`：Anthropic 为 direct + cache read + cache write；OpenAI/Codex 为 input/prompt 总量。
- 保持既有 input/cacheRead/cacheWrite/output/total 字段兼容。

验收：混合 Claude/Codex fixture 的 `accountedInput`、cache hit 数学断言准确。

### G2. 会话级证据账本

- `--sessions` 输出逐 JSONL 会话记录、provider、请求数可信度、原始用量与派生指标。
- Claude 逐请求累加并记录峰值；Codex 有 `last_token_usage` 时记录请求峰值，无时明确 unavailable。
- 不输出对话正文与绝对日志路径。

验收：fixture 断言会话数、provider、已知/未知请求计数、峰值与隐私字段。

### G3. 比例陷阱与 Context Floor proxy

- 输出 cache hit、cache write、reasoning 比例。
- 输出平均/峰值 accounted input、cache read/write per request；无法确定则为 `null`，不伪造。
- 指标命名明确为观测量或 proxy。

验收：零分母、混合 provider、Codex 累计-only 三类边界均有断言。

### G4. 显式预算闸与证据边界

- 新增 `--min-cache-hit`、`--max-cache-write`、`--max-input-per-request`、`--max-cache-read-per-request`。
- 未越界 exit 0；越界或请求指标不可得 exit 1；参数错误 exit 2。
- 可选 `--cost-usd`、`--changed-lines`、`--quality-exit`；只计算显式证据，不从 output/reasoning 猜代码量或质量。

验收：通过、越界、unavailable、非法参数、证据齐/缺 fixture 皆断言。

### G5. 交付面对账

- README、CHANGELOG、help、模板规范同步指标定义与不可归因边界。
- 安装沙箱继续验证 `token-usage` 可执行。
- `pnpm test` 全绿，CodeGraph 刷新后状态文档有符号与验证证据。

## 非目标

- 不做代理、不改宿主请求、不自动 `/compact`。
- 不实现 AST runtime、Rust LangGraph、语义缓存或模型路由。
- 不内置价格表；成本须用户显式输入，免随供应商价格漂移。
- 不把高 cache hit、reasoning ratio 或 changed lines 解释为高质量。

## 停机条件

- 任何既有测试回归；
- Claude/Codex 口径无法以 fixture 唯一判定；
- 新指标需读取对话正文或上传日志；
- 阈值默认改变现有命令退出行为。

## 完成闸

```text
pnpm test
node bin/token-usage.mjs --help
codegraph sync
codegraph status
```
