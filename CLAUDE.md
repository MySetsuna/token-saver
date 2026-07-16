# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目定位

Token Saver 是一个 LLM Token 节省方案的**集成项目**：核心交付物是安装脚本与注入模板，不是应用代码。四层架构：终端输出压缩（内置 squeez）→ 代码库瘦身（repomix，外部 npx）→ Prompt 缓存锚定（静态前置规范）→ 输出压缩（精简 + 文言文「微言大义协议」，安装即默认启用）。金科玉律：**代码块与错误信息 100% 无损，仅压缩解释性文本**。

## 常用命令

```bash
pnpm test                    # 全量自检：squeez 压缩逻辑 + install.sh 沙箱幂等性
bash tests/test-squeez.sh    # 同上（无需 pnpm）
echo test | bash bin/squeez  # 手测压缩器
```

测试用 `HOME=$(mktemp -d)` 沙箱运行 install.sh，不会碰真实用户配置。**手动调试 install.sh 时也务必如此**——`--claude-code` 会写 `~/.claude/CLAUDE.md`。

## 架构要点

- `install.sh` — 唯一入口，按 `--claude-code` / `--codex` / `--cursor` / `--aider` / `--project` 分发。核心函数 `inject_block`：用 `<!-- token-saver:begin/end -->` 标记做幂等注入（重复运行整块替换），首次修改前备份 `*.token-saver.bak`。改任何写入逻辑必须保持这两个不变量。
- `bin/squeez` — bash + awk 零依赖压缩器：去 ANSI → 折叠重复行 `(xN)` → 超过 `SQUEEZ_MAX_LINES` 时保留头/尾/错误行及上下文。错误行（error/fail/warn/exception/panic…）**永远保留**，这是产品承诺。
- `config/*.template` — 各平台注入内容。`claude-md.template` 同时用于 Claude Code（`~/.claude/CLAUDE.md`）和 Codex（`~/.codex/AGENTS.md`），内容保持平台无关；Cursor/Aider 有独立精简版模板。
- 文言模式不是 Skill：用户要求**安装即默认生效**，所以协议直接写在 `claude-md.template` 里，没有按需触发的 skill 形式。
- 根目录 `.claude.md`（小写）是历史遗留的产品说明模板，与本文件无关。

## 约定

- 仓库语言为中文（文档、脚本输出、注释），新增内容保持中文。
- 脚本面向 bash（Windows 下走 Git Bash），不写 PowerShell 版本。
- 当前开发在 `master`，PR 目标主分支是 `main`。
