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
node bin/cache-lint.mjs <文件>    # L3 缓存杀手检查（命中即 exit 1）
bash bin/pack-repo.sh             # L2 repomix 打包并实测前后 token（需联网）
```

测试用 `HOME=$(mktemp -d)` 沙箱运行 install.sh，不会碰真实用户配置。**手动调试 install.sh 时也务必如此**——`--claude-code` 会写 `~/.claude/CLAUDE.md`。

## 架构要点

- `install.sh` — 唯一入口，按 `--claude-code` / `--codex` / `--ridgecode` / `--cursor` / `--aider` / `--project` 分发。核心函数 `inject_block`：用 `<!-- token-saver:begin/end -->` 标记做幂等注入（重复运行整块替换，字节级幂等），首次修改前备份 `*.token-saver.bak`。改任何写入逻辑必须保持这两个不变量。
- 抗指令漂移 hook（`--claude-code` 独有）：复制 `config/reminder.md` → `~/.claude/token-saver-reminder.md`，并用 node 向 `settings.json` 的 `UserPromptSubmit` hooks 注入 `cat` 该文件的命令，每回合重锚定输出人格路由。注入同样幂等（按 `token-saver-reminder` 字符串判重）且先备份 `settings.json.token-saver.bak`；无 node 则跳过。
- `bin/squeez` — bash + awk 零依赖压缩器：去 ANSI → 折叠重复行 `(xN)` → 超过 `SQUEEZ_MAX_LINES` 时保留头/尾/错误行及上下文。错误行（error/fail/warn/exception/panic…）**永远保留**，这是产品承诺。Windows 安装时额外生成 `squeez.cmd` 垫片（CRLF、烤入 Git Bash 绝对路径以避开 WSL bash）；`bin/squeez` 开头把 `/usr/bin` 补进 PATH 正是为配合该垫片。
- `config/*.template` — 各平台注入内容。`claude-md.template` 同时用于 Claude Code（`~/.claude/CLAUDE.md`）和 Codex（`~/.codex/AGENTS.md`），内容保持平台无关；Cursor/Aider 有独立精简版模板。`ridgecode.template`（`--ridgecode`）注入 `~/.ridge/AGENTS.md` 作 RidgeCode 全局规则——**刻意不含文言协议**（RidgeCode 常跑弱模型，正确率优先，只压结构不换文体），依赖 ridge-code 侧 `load_project_rules` 的全局文件读取。
- 文言模式不是 Skill：用户要求**安装即默认生效**，所以协议直接写在 `claude-md.template` 里，没有按需触发的 skill 形式。
- Ponytail 协议同理**默认启用**：写在 `claude-md.template`（Claude Code/Codex）、`cursorrules.template`、`aider-conventions.template` 里，并进 `reminder.md` 每回合抗漂移。它是建造维度（少写码），与输出人格路由正交；改这几个模板须同步保留其「梯子 + 不可简化清单」，`tests/test-squeez.sh` 会 grep `Ponytail` 断言其默认注入。转义词「stop ponytail」/「normal mode」。
- `bin/cache-lint.mjs`（L3 确定性）— node 标准库零依赖，逐行匹配「缓存杀手」（日期/时钟/UUID/长 hex/绝对家目录/`Date.now`）命中即报行号并 `exit 1`；把「静态区禁动态内容」的软准则变成机器检查。`--fix` 把每处缓存杀手替换为 `⟨removed⟩` 占位（占位本身不含杀手，故 fix 后再 lint 必净）：默认输出到 stdout 预览不改文件，`--fix --write` 才就地改并备份 `*.cache-lint.bak`。已入 `pnpm test`（断言模板干净 + 正负样本 + fix 预览/写回/备份）。新增/改缓存杀手规则须保证 `config/*.template` 仍能通过，且同步改 `config/cache-lint-hook.mjs` 的内联规则。
- `config/cache-lint-hook.mjs`（L3 写入前守护，`--claude-code` 独有）— PreToolUse 警告钩子：**规则内联自足**（与 cache-lint.mjs 保持一致，故意不共享模块以免跨平台 import 脆弱）。install 复制它 → `~/.claude/token-saver-cache-hook.mjs`，并向 `settings.json` 的 `PreToolUse`（matcher `Write|Edit`）幂等注入（判重字符串 `token-saver-cache-hook`）。仅当写入目标是入缓存静态文件（`CLAUDE.md`/`AGENTS.md`/`.cursorrules`/`.claude/` 下）且内容含缓存杀手时，向 stderr 警告，**恒 `exit 0` 绝不阻断**（用户选的「仅警告」）。改行为须守住「恒 0」不变量。
- `bin/pack-repo.sh`（L2 测量化）— `git ls-files` 过滤二进制 → token-count 求源码合计 → `npx -y repomix --remove-comments --remove-empty-lines` 打包 → token-count 求打包后，打印前后差。加 `--compress` 旗则再跑一次 `repomix --compress`（抽签名/弃函数体）做对比。repomix 仍是唯一真外部工具（按需 npx，不入依赖）。诚实注意：文档/脚本仓打包**任何模式都可能反增**（XML 脚手架开销 > 所省，实测本仓 -2%~-3%），--compress 只对有函数体的代码仓划算；产物 `repomix-output*.xml` 已 gitignore。因需联网，**不进** `pnpm test` 也不进 `bench`（后者刻意保持无网络）。
- 根目录 `.claude.md`（小写）是历史遗留的产品说明模板，与本文件无关。

## 约定

- 仓库语言为中文（文档、脚本输出、注释），新增内容保持中文。
- 脚本面向 bash（Windows 下走 Git Bash），不写 PowerShell 版本。
- 开发与 PR 主分支均为 `main`。
