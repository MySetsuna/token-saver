# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

Token Saver 是一个 LLM Token 节省方案的**集成项目**：核心交付物是安装脚本与注入模板，不是应用代码。五层架构：终端输出压缩（内置 squeez）→ 代码库瘦身（repomix，外部 npx）→ Prompt 缓存锚定（静态前置规范）→ 输出压缩（精简 + 文言文「微言大义协议」）→ 代码建造精简（Ponytail 协议：少写码本身即省 token）。后两层安装即默认启用，正交——一管「怎么说」、一管「造什么」。金科玉律：**代码块与错误信息 100% 无损，仅压缩解释性文本**。

## 常用命令

```bash
pnpm test                    # 全量自检：squeez 压缩逻辑 + install.sh 沙箱幂等性
bash tests/test-squeez.sh    # 同上（无需 pnpm）
echo test | bash bin/squeez  # 手测压缩器
node bin/token-count.mjs <文件>   # 本地 token 估算（CJK≈1 字/token，其余≈4 字符/token）
```

测试用 `HOME=$(mktemp -d)` 沙箱运行 install.sh，不会碰真实用户配置。**手动调试 install.sh 时也务必如此**——`--claude-code` 会写 `~/.claude/CLAUDE.md`。

## 架构要点

- `install.sh` — 唯一入口，按 `--claude-code` / `--codex` / `--cursor` / `--aider` / `--project` 分发。核心函数 `inject_block`：用 `<!-- token-saver:begin/end -->` 标记做幂等注入（重复运行整块替换，字节级幂等），首次修改前备份 `*.token-saver.bak`。改任何写入逻辑必须保持这两个不变量。
- 抗指令漂移 hook（`--claude-code` 独有）：复制 `config/reminder.md` → `~/.claude/token-saver-reminder.md`，并用 node 向 `settings.json` 的 `UserPromptSubmit` hooks 注入 `cat` 该文件的命令，每回合重锚定输出人格路由。注入同样幂等（按 `token-saver-reminder` 字符串判重）且先备份 `settings.json.token-saver.bak`；无 node 则跳过。
- `bin/squeez` — bash + awk 零依赖压缩器：去 ANSI → 折叠重复行 `(xN)` → 超过 `SQUEEZ_MAX_LINES` 时保留头/尾/错误行及上下文。错误行（error/fail/warn/exception/panic…）**永远保留**，这是产品承诺。Windows 安装时额外生成 `squeez.cmd` 垫片（CRLF、烤入 Git Bash 绝对路径以避开 WSL bash）；`bin/squeez` 开头把 `/usr/bin` 补进 PATH 正是为配合该垫片。
- `config/*.template` — 各平台注入内容。`claude-md.template` 同时用于 Claude Code（`~/.claude/CLAUDE.md`）和 Codex（`~/.codex/AGENTS.md`），内容保持平台无关；Cursor/Aider 有独立精简版模板。
- 文言模式不是 Skill：用户要求**安装即默认生效**，所以协议直接写在 `claude-md.template` 里，没有按需触发的 skill 形式。
- Ponytail 协议同理**默认启用**：写在 `claude-md.template`（Claude Code/Codex）、`cursorrules.template`、`aider-conventions.template` 里，并进 `reminder.md` 每回合抗漂移。它是建造维度（少写码），与输出人格路由正交；改这几个模板须同步保留其「梯子 + 不可简化清单」，`tests/test-squeez.sh` 会 grep `Ponytail` 断言其默认注入。转义词「stop ponytail」/「normal mode」。
- 根目录 `.claude.md`（小写）是历史遗留的产品说明模板，与本文件无关。

## 约定

- 仓库语言为中文（文档、脚本输出、注释），新增内容保持中文。
- 脚本面向 bash（Windows 下走 Git Bash），不写 PowerShell 版本。
- 开发与 PR 主分支均为 `main`。
