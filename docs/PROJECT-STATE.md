# token-saver · 项目现状（PROJECT-STATE）

> **唯一**上传 NotebookLM 的文档。每轮**覆盖式重写**。历史见 git 与 `docs/iterations/`。

## 项目是什么

Token Saver 是 LLM Token 节省方案的**集成项目**：核心交付物是安装脚本与注入模板，不是应用代码、也不是 runtime 代理。五层：

1. 终端输出压缩（内置 `squeez`）
2. 代码库瘦身（`repomix` / `pack-repo`，外部 npx）
3. Prompt 缓存锚定（静态前置规范 + `prompt-prefix-check`；文档承诺 `cache-lint`）
4. 输出压缩（语义预算 terse/normal/audit + 文言/Caveman 语言路由）
5. 代码建造精简（Ponytail 协议：少写码本身省 token）

金科玉律：**代码块与错误信息 100% 无损，仅压缩解释性文本**。适配 Claude Code / Codex / Cursor / Aider / RidgeCode。

**非目标**：不整仓 fork Headroom 类代理产品；不把本仓改成 LLM 网关。

## 稳定段：不可动摇的设计主线 / 已锁定决策

- **交付物 = 安装 + 模板 + 零/轻依赖工具链**：`install.sh` / `install.ps1` 幂等注入（`<!-- token-saver:begin/end -->`），首次改前备份 `*.token-saver.bak`
- **真实计量优先**：`token-usage --all` 读服务端 usage；`token-count` 仅粗估
- **各层收益重叠不相加**：同任务 baseline/优化后对比才下结论
- **错误行永不丢**（`squeez` 产品承诺）
- **输出人格默认启用且抗漂移**：中文文言微言大义 / 英文 Caveman；`reminder` hook 每回合重锚定（Claude Code）
- **Ponytail 默认启用**，与输出路由正交（管造什么 vs 管怎么说）
- **maker ≠ checker**：验证只认 `pnpm test` 等确定性信号

## 当前架构（由 codegraph + 源码事实勾勒）

### 目录与模块

| 路径 | 职责 |
|---|---|
| `install.sh` / `install.ps1` | 唯一安装入口；`inject_block` 幂等注入；分发 `--claude-code`/`--codex`/`--cursor`/`--aider`/`--ridgecode`/`--project`/`--openai-compat` |
| `bin/squeez` | bash+awk 终端压缩：去 ANSI、折叠重复、头尾截断、错误行保留 |
| `bin/token-count.mjs` | CJK 感知粗估 |
| `bin/token-usage.mjs` | Claude/Codex JSONL usage 聚合 |
| `bin/prompt-prefix-check.mjs` | 两次 prompt 快照公共前缀/hash 稳定性 |
| `bin/pack-repo.sh` | repomix 打包并 token 前后差 |
| `bin/run-bash.mjs` | Windows 下经 Git Bash 跑 shell 测试/脚本 |
| `config/*.template` | 各平台注入模板（claude-md / cursorrules / aider / ridgecode） |
| `config/reminder.md` + `reminder-hook.mjs` | 抗指令漂移 |
| `tests/test-squeez.sh` | squeez + install 沙箱幂等自检 |
| `bench/run.sh` | 现场基准（确定性 vs 行为性） |

### codegraph 索引（2026-07-24）

- `codegraph init -i`：5 个 JS 文件，59 nodes / 83 edges
- 可解析符号集中在 `bin/*.mjs` 与 `config/reminder-hook.mjs`
- bash（`install.sh`、`squeez`）不在 AST 图内，以源码为准

### 关键接口（源码）

- `inject_block(目标, 模板)`：标记块整块替换，字节级幂等
- `install_squeez`：复制到 `TOKEN_SAVER_BIN`（默认 `~/.local/bin`），Windows 写 `squeez.cmd` 垫片
- `tokens`（token-count）：`CJK + (len-CJK)/4`
- 质量闸：`pnpm test` → `node bin/run-bash.mjs tests/test-squeez.sh`

### 能力对照（落地状态）

| 能力 | 状态 |
|---|---|
| squeez 终端压缩 | ✅ 内置 |
| token-usage 真实计量 | ✅ 内置 |
| prompt-prefix-check | ✅ 内置 |
| pack-repo / repomix | ✅ 集成 |
| 语义预算 + 语言路由 | ✅ 模板默认 |
| Ponytail | ✅ 模板默认 |
| 抗漂移 reminder hook | ✅ Claude Code |
| tamp 输入去重 | ⚠️ 高级指引（`--openai-compat`） |
| LLMLingua 上下文压缩 | ⏳ README 规划，未实现 |
| cache-lint.mjs（离线 CLI） | ✅ 内置；**无** PreToolUse hook |
| usage-delta | ✅ 内置 |
| install --uninstall | ✅ |
| LLMLingua | ❌ 明确不计划内置 |

## 本轮做了什么

- v1.3.0：兑现 cache-lint CLI、usage-delta、uninstall、squeez 小增强、模板瘦身、文档诚实分层
- 此前：NLM 初始化 + Headroom 调研否定合仓（`docs/iterations/2026-07-24-headroom-research.md`）

## 确定性验证证据

```text
pnpm test → ✅ 全部自检通过（含 cache-lint 正负样本、uninstall、JSON_MAX、扩展错误行）
```

## 能力对照（距最终目标差什么）

- 轻量集成主线已闭环
- 重代理/重 ML 压缩不在范围；需要时并列外部工具

## 开放问题

1. 无紧急决策。runtime JSON 极重 → 外挂 Headroom。
