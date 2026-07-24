# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

Token Saver 是一个 LLM Token 节省方案的**集成项目**：核心交付物是安装脚本与注入模板，不是应用代码。五层架构：终端输出压缩（内置 squeez）→ 代码库瘦身（repomix，外部 npx）→ Prompt 缓存锚定（静态前置 + `prompt-prefix-check` / `cache-lint`）→ 输出压缩（语义预算 + 文言/Caveman）→ 代码建造精简（Ponytail）。后两层安装即默认启用，正交。金科玉律：**代码块与错误信息 100% 无损，仅压缩解释性文本**。

## 常用命令

```bash
pnpm test                    # 全量自检：squeez + install 沙箱幂等 + cache-lint + usage-delta
bash tests/test-squeez.sh    # 同上（无需 pnpm）
echo test | bash bin/squeez  # 手测压缩器
node bin/token-count.mjs <文件>   # 本地 token 粗估
node bin/cache-lint.mjs <文件>    # L3 缓存杀手检查（命中 exit 1）
node bin/usage-delta.mjs a.json b.json  # 两次 token-usage --json 快照差
bash bin/pack-repo.sh             # L2 repomix 打包并实测前后 token（需联网）
```

测试用 `HOME=$(mktemp -d)` 沙箱运行 install.sh，不会碰真实用户配置。**手动调试 install.sh 时也务必如此**。

## 架构要点

- `install.sh` — 唯一入口（`install.ps1` 仅转调 Git Bash）。`inject_block` 用 `<!-- token-saver:begin/end -->` 幂等注入，首次改前备份 `*.token-saver.bak`。`--uninstall` 从备份恢复并移除 reminder。
- 抗漂移 hook（`--claude-code`）：`reminder.md` + `reminder-hook.mjs` → `UserPromptSubmit`；**不再**安装 PreToolUse 缓存 hook（已迁移移除，测试断言缺席）。
- `bin/squeez` — 去 ANSI、折叠重复、截断；错误行永留。可选 `SQUEEZ_JSON_MAX>0` 截断超长单行 JSON。
- `bin/cache-lint.mjs` — 离线扫日期/时钟/UUID/长 hex/家目录/`Date.now`；`--fix [--write]`。模板必须干净。无运行时 PreToolUse 钩子。
- `bin/usage-delta.mjs` — 比较两次 `token-usage --json`，同任务装前/装后用。
- `config/claude-md.template` — **各端统一**完整规范（Claude / Codex / Grok / RidgeCode / Cursor / Aider）；含文言 + Ponytail。`reminder.md` 仅 Claude 抗漂移。
- Ponytail 与输出路由默认启用；`tests/test-squeez.sh` grep 断言。
- `bin/pack-repo.sh` — 需联网，不进 `pnpm test`/`bench`。

## 约定

- 仓库语言为中文（文档、脚本输出、注释）。
- 脚本面向 bash（Windows 下 Git Bash），不写 PowerShell 业务逻辑。
- 开发与 PR 主分支均为 `main`。
