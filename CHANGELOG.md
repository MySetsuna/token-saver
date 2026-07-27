# Changelog

## Unreleased

- **token-usage 会话证据账本**：新增 `--sessions`，按 provider 正确归一 `accountedInput`，输出 cache hit/write、reasoning、Context Floor proxy 与逐请求峰值；只显文件名，不读/曝对话正文
- **Context Budget 闸**：新增 `--min-cache-hit`、`--max-cache-write`、`--max-input-per-request`、`--max-cache-read-per-request`；越界 exit 1，请求数据不可得时 fail closed
- **代码产出证据边界**：仅据显式 `--cost-usd`、`--changed-lines`、`--quality-exit` 计算；不从 reasoning/output token 猜代码量、质量或因果收益
- Claude/Codex fixtures 覆盖独立缓存字段、cached-input 子集、Codex 累计量、逐请求峰值、零/不可得边界与预算退出码
- **三端抗漂移对齐**：Claude/Codex 以 `UserPromptSubmit.additionalContext` 每回合单行重锚；Grok 因被动 hook stdout 不进入上下文，改用仅命中明确客套/续问时触发的 `Stop` 纠偏，避免每轮额外推理
- `--all` 现安装 Claude Code、Codex 与 Grok；Codex hook 保留原配置且提示首次 `/hooks` 信任，三端 hook/reminder 均可卸载

## v1.3.1 (2026-07-24)

- **规范各端一致**：RidgeCode / Cursor / Aider 改用与 Claude/Codex/Grok 同一 `claude-md.template`（含文言）；删除弱模型精简模板 `ridgecode`/`cursorrules`/`aider-conventions`
- 新增 `--grok` 安装入口（`~/.grok/AGENTS.md`）

## v1.3.0 (2026-07-24)

兑现文档承诺、压注入体积、补计量与回滚，**不**引入代理/重依赖。

### 新功能 / 兑现
- **cache-lint（CLI）**：`bin/cache-lint.mjs` 扫日期/时钟/UUID/长 hex/家目录/`Date.now`；`--fix [--write]` + 备份；入 `pnpm test` 与安装工具链。**不**恢复 PreToolUse 缓存 hook（产品已弃用，仅离线检查）
- **usage-delta**：两次 `token-usage --json` 快照差，便于同任务装前/装后对照
- **squeez**：扩展错误信号（TypeError/npm ERR/ENOENT 等）；可选 `SQUEEZ_JSON_MAX` 截断超长单行 JSON（默认关）
- **install --uninstall**：从 `*.token-saver.bak` 恢复并移除 reminder

### 精简与诚实
- **claude-md.template** 压缩篇幅（少例多规），每会话注入 token 税下降
- README：确定性 vs 行为性分层；LLMLingua 标为不计划内置；卸载与 usage 对比步骤
- CLAUDE.md 与实现一致：无 cache-lint PreToolUse hook

## v1.2.0 (2026-07-17)

新增两层确定性能力与建造精简层，L2/L3 从「劝导」升为「可测/可强制」，全部数字诚实分级、无臆造。

### 新功能
- **Ponytail 建造精简（L5）**：懒开发者协议纳入体系、默认启用，与输出人格路由正交（一管怎么说、一管造什么）。写入 `claude-md`/`cursorrules`/`aider` 模板 + `reminder` 抗漂移。转义词「stop ponytail」/「normal mode」
- **cache-lint（L3 确定性）**：`bin/cache-lint.mjs` 零依赖扫描静态文件的缓存杀手（日期/时钟/UUID/长 hex/绝对家目录/`Date.now`），命中即 `exit 1`；`--fix` 自动剥离为 `⟨removed⟩` 占位（默认 stdout 预览，`--write` 就地改并备份 `*.cache-lint.bak`）。已入 `pnpm test`
- **缓存守护 hook（L3 写入前）**：`--claude-code` 幂等注册 PreToolUse 警告钩子，改写入缓存文件（`CLAUDE.md`/`AGENTS.md`/`.cursorrules`/`.claude/`）含缓存杀手时当场提醒，**恒不阻断编辑**
- **pack:repo（L2 测量化）**：`bin/pack-repo.sh` repomix 打包并实测前后 token，`--compress` 对比抽签名模式
- **真实基准 bench**：`pnpm bench` 现场跑出「确定性」（squeez 87%）与「行为性·潜在」（文言 51% / caveman 61% / Ponytail 91%）两类数据，含 `WARNING`/`FAIL` 承诺校验
- **文言电报体优化**：文言协议再借野人之狠（删虚字/许碎片/压骨架），实测节省 42%→51%

### 诚实化
- 以 `pnpm bench` 现场真数替换 README 旧臆造对比（曾有 32000→8400 等杜撰值）
- 修正 repomix「50%+」等未证实营销数字为「视仓库而定，实测」——实测本仓（文档/脚本）打包反增 2%~3%，印证 repomix 非普适

## v1.1.1 (2026-07-16)

- **抗指令漂移**：`--claude-code` 注册 UserPromptSubmit hook，每回合注入一行人格提醒（约 30 token），修复长对话中输出人格逐渐失效的问题
- settings.json 安全合并：只追加 hook 条目，原有设置原样保留，首次修改自动备份

## v1.1.0 (2026-07-16)

- **输出人格路由**：按用户提问语言自动分流——中文→微言大义（文言），英文→Caveman（协议源自社区 JuliusBrussee/caveman），其他语言→该语言精简版
- 新增清晰豁免规则：安全警告、不可逆操作确认自动恢复完整表述
- 未采用 caveman 插件直装：其全局常开、且中文场景回中文 caveman 而非文言，与语言路由冲突；改为集成其协议文本

## v1.0.0 (2026-07-16)

首个正式版：四层 Token 节省架构完整落地。

### 功能
- **squeez** 终端输出压缩器（bash+awk 零依赖）：去 ANSI、重复行折叠、智能截断；错误行及上下文永远保留。实测压缩率 73%（编译日志）～97%（大日志）
- **squeez.cmd** Windows 垫片：PowerShell/CMD 直接可用
- **token-count** 本地 Token 估算器（CJK 感知）
- **多平台一键安装**：`--claude-code` / `--codex` / `--cursor` / `--aider` / `--project` / `--openai-compat`
- **微言大义（文言文）协议**：随 Claude Code / Codex 安装默认启用，输出再省 50%+；代码块与错误信息 100% 无损
- **缓存锚定规范**：静态前置、禁动态变量，注入全局配置

### 质量保证
- 所有写入字节级幂等（标记块整块替换），首次修改前自动备份 `*.token-saver.bak`
- 自检覆盖：压缩逻辑、全部安装分支的沙箱幂等性（`pnpm test`）
