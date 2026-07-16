# 🗜️ Token Saver — 完整的 Token 节省系统

一个开源的、**零学习曲线**的 LLM Token 节省完整解决方案。从输入压缩、输出精简、到架构优化，帮你在用 Claude Code 时 **节省 70%-90% 的 Token 成本**。

> **适配**: Claude Code / Claude API / Aider / Cursor  
> **开箱即用**: 一键安装脚本，无需繁琐配置  
> **可选文言文输出**: 激活"古文黑魔法"，再省 50% 输出 Token

---

## 🎯 快速开始

### 1️⃣ 自动安装（推荐）

```bash
# 克隆项目
git clone https://github.com/MySetsuna/token-saver.git
cd token-saver

# 一键接入 Claude Code（squeez + 全局规范注入，文言模式默认启用）
bash install.sh --claude-code

# 或接入 Codex CLI / Cursor / Aider
bash install.sh --codex
bash install.sh --cursor
bash install.sh --aider

# 通用 OpenAI 兼容端点优化指引
bash install.sh --openai-compat
```

所有写入均幂等（重复运行只更新 `<!-- token-saver -->` 标记块），首次修改前自动备份 `*.token-saver.bak`。

### 2️⃣ 验证与日常使用

```bash
pnpm test                      # 运行自检（squeez + cache-lint + 安装器幂等性）
pnpm token:count README.md     # 估算文件 Token 成本
pnpm pack:repo                 # 打包瘦身代码库并实测前后 token 差（L2，需联网）
pnpm cache:lint <文件...>      # 检查静态文件是否混入缓存杀手（L3，零依赖）
<某长输出命令> 2>&1 | squeez    # 手动压缩任意终端输出
```

> **L2/L3 已从「劝导」升为「可测/可强制」**：`pack:repo` 把 repomix 瘦身变成可复现的实测数（省耗视仓库而定——注释密集的代码仓才划算，本仓这类文档仓可能反增）；`cache:lint` 把「缓存区禁动态内容」的准则变成会 `exit 1` 的确定性检查，已入 `pnpm test`。

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                  Claude Code / Cursor                   │
│                                                          │
├─────────────┬──────────────┬─────────────┬──────────────┤
│  Layer 1    │  Layer 2     │   Layer 3   │   Layer 4    │
│ 终端输入压缩 │ 上下文去噪   │  Prompt     │  输出人格    │
├─────────────┼──────────────┼─────────────┼──────────────┤
│  squeez     │ repomix      │ 全局规范    │ 人格路由     │
│  (内置)     │ (npx)        │ (缓存锚定)  │(中文言/英cave)│
├─────────────┼──────────────┼─────────────┼──────────────┤
│  节省 90%   │  节省 50%    │  节省 50%   │  节省 75%    │
│  (终端噪音) │  (代码冗冗)  │  (历史)     │  (废话)      │
└─────────────┴──────────────┴─────────────┴──────────────┘
                        ↓
              最终节省: 70%-90% Token
```

> 另有正交的**第五层 Ponytail 建造精简**（少写代码即省 token），随规范默认注入，详见下文「代码建造精简」。

---

## 📦 核心工具链

| 工具 | 职责 | 节省幅度 | 状态 |
|------|------|---------|------|
| **squeez** (`bin/squeez`) | 终端输出压缩器（去 ANSI、折叠重复、智能截断） | 73-97%（实测） | ✅ 内置 |
| **repomix** | 代码库打包瘦身（`npx -y repomix`） | 视仓库而定，`pnpm pack:repo` 实测 | ✅ 集成 |
| **cache-lint** (`bin/cache-lint.mjs`) | 缓存杀手检查器（禁静态区混入时间戳/UUID/绝对路径等） | 确定性守护缓存命中 | ✅ 内置 |
| **输出人格路由** | 中文→微言大义（文言），英文→caveman，按语言自动分流 | 65-85% | ✅ 内置 |
| **Ponytail 建造精简** | 懒开发者协议：YAGNI、复用优先、最短 diff、不做未请求的抽象 | 少写码即省 | ✅ 内置 |
| **prompt-caching 规范** | 静态前置 / 禁动态变量，注入到全局规范 | 50-90% | ✅ 内置 |
| **tamp** | API 代理输入去重（`--openai-compat` 指引） | 50% | ⚠️ 高级 |
| **LLMLingua** | 上下文压缩（Python，重依赖） | 2x-20x | ⏳ 规划 |

---

## 🚀 详细配置

### 场景 1: Claude Code 用户（最常见）

```bash
# 安装 squeez 到 ~/.local/bin，并注入全局规范到 ~/.claude/CLAUDE.md
bash install.sh --claude-code

# 验证安装成功
echo test | squeez
```

此时你的 Claude Code 会：
- ✅ 长输出命令自动走 `| squeez` 压缩（规范驱动，90%+ 减少）
- ✅ 遵循缓存锚定原则（静态前置、禁动态变量）
- ✅ 文言文（微言大义）输出默认启用，说「白话模式」临时恢复
- ✅ 宏观分析前先 repomix 打包，剥离代码库冗余

### 场景 2: 输出人格路由（默认已启用）

`--claude-code` / `--codex` 安装后，按**用户提问语言**自动分流输出人格：

| 提问语言 | 输出人格 | 效果 |
|---|---|---|
| 中文 | 微言大义（半文半白） | `props` 每渲染皆新对象，致重绘。`useMemo` 包之则免。 |
| 英文 | Caveman（源自 [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)） | New object ref each render. Wrap in `useMemo`. |
| 其他 | 该语言精简版 | 压风格，不换语言 |

- 代码块与错误信息 100% 无损，仅压缩解释性文本
- 安全警告、不可逆操作确认自动豁免（完整表述）
- 说「白话模式」/ "normal mode" 临时恢复常规输出

不想默认启用？删除 `~/.claude/CLAUDE.md` 中 token-saver 标记块内的「输出人格路由」小节即可。

### 代码建造精简（Ponytail 协议，默认已启用）

前面几层压缩「怎么说」，这一层管「造什么」——**少写代码本身就是省 token**：写出来的每一行都要在当下生成、日后反复进上下文。`--claude-code` / `--codex` / `--cursor` / `--aider` 安装后随规范一并注入，与输出人格路由正交、同为默认开启。

核心是一把「懒梯子」，改动前先读懂问题，止于**首个成立之档**：

> YAGNI（臆测需求即跳过）→ 复用本仓已有 → 标准库 → 平台原生特性 → 已装依赖 → 一行搞定 → 方才最小实现

- 不做未经请求的抽象（无单实现的接口、单产物的工厂、恒定值的配置）
- 最短可用 diff 取胜；改 bug 修根因（先 grep 全部调用方，共有函数处一次修好）
- **绝不简化掉**：输入校验、防丢数据的错误处理、安全措施、无障碍基础、用户明确要求之物
- 每回合经抗漂移 hook 重锚定，长对话不失效；说「stop ponytail」/「normal mode」临时恢复

### 场景 3: 集成到 CI/CD 构建流水线

```yaml
# .github/workflows/build.yml
- name: "Compress Code Context for LLM"
  run: |
    npm run compress:repo                        # repomix 打包（瘦身 50%）
    npm run build 2>&1 | bin/squeez > build.log  # build 日志去噪（80%+）
```

---

## 📊 效果对比（真实基准，可复现）

数字由 `pnpm bench` 现场跑出，非估算：对合成的典型终端噪声实测 squeez 压缩前后 token，并对同一技术解释对比白话与文言。自己跑一遍即可复现：

```bash
pnpm bench          # 人读表格
pnpm bench --md     # 输出 markdown
```

<!-- token-saver:bench:begin -->
| 场景 | 原始 Token | 优化后 Token | 节省 |
|------|-----------:|-------------:|-----:|
| 依赖安装日志（squeez） | 3093 | 617 | **80%** |
| 构建编译日志（squeez） | 8715 | 977 | **88%** |
| 测试运行输出（squeez） | 5613 | 510 | **90%** |
| 技术解释白话→文言（人格路由） | 65 | 32 | **50%** |
| **终端三项合计** | **17421** | **2104** | **87%** |
<!-- token-saver:bench:end -->

> 基准内含承诺校验：压缩后若 `WARNING` / `FAIL` 行丢失则直接失败退出——**错误行永不被压掉**。

### 真实 LLM 输出对比（同一问，两种人格）

问：*JS 事件循环中宏任务与微任务的执行顺序，为何 Promise 回调先于 setTimeout？* 同一答案，白话 257 token，文言（微言大义）145 token，**实测节省 43%**——语义无损，仅剥去客套与冗述。放大到整轮多次问答，输出层的省耗相当可观。

---

## 🛠️ 高级用法

### 自定义压缩策略

squeez 通过环境变量配置：

```bash
SQUEEZ_MAX_LINES=200    # 超过此行数才截断（默认 200）
SQUEEZ_HEAD=40          # 截断时保留的开头行数
SQUEEZ_TAIL=40          # 截断时保留的结尾行数
SQUEEZ_ERR_CONTEXT=2    # 错误行上下文保留行数（错误行永远保留）
```

### 本地 Token 计数器

```bash
# 估算文件或管道内容的 Token 成本（CJK ≈ 1 token/字，其余 ≈ 4 字符/token）
npm run token:count README.md
cat build.log | node bin/token-count.mjs

# 输出示例:
# chars: 12143  est. tokens: 6890
```

---

## 📂 项目结构

```
token-saver/
├── install.sh                        # 一键安装脚本（幂等，自动备份）
├── bin/
│   ├── squeez                        # 终端输出压缩器（bash + awk，零依赖）
│   └── token-count.mjs               # 本地 Token 估算器
├── config/
│   ├── claude-md.template            # Claude Code / Codex 全局规范（含文言协议）
│   ├── cursorrules.template          # Cursor 规范
│   └── aider-conventions.template    # Aider CONVENTIONS
├── bench/
│   └── run.sh                        # Token 节省基准（真实可跑，含承诺校验）
├── tests/
│   └── test-squeez.sh                # 自检（squeez + 安装器幂等性）
├── package.json
├── README.md
└── LICENSE                           # Apache 2.0
```

---

## 🎓 原理深度解析

### 四层协同架构

#### Layer 1: 终端输入压缩（squeez）
- 全局规范驱动：长输出命令自动追加 `| squeez` 管道
- 剥离 ANSI 码、折叠重复行、智能截断（错误行永远保留）
- 效果: 实测 73-97% 压缩

#### Layer 2: 代码库去噪（repomix）
- 自动剥离注释、遵循 .gitignore、XML 结构排版
- 效果: 项目打包瘦身 50%+

#### Layer 3: Prompt 缓存锚定（全局 CLAUDE.md）
- 遵循"静态在前，动态在后"原则
- 静态区严禁时间戳等动态变量
- 缓存命中费用降低 90%

#### Layer 4: 输出人格压缩（按语言路由）
- 中文→微言大义（字符数减少 80%），英文→caveman（token 减少 65%）
- 去除客套话、冗长解释；安全警告自动豁免
- 代码块 100% 保留，无任何损失

---

## 🔌 集成第三方工具

### 已支持

- ✅ Claude Code (官方支持)
- ✅ Cursor IDE
- ✅ Aider AI
- ✅ OpenAI API 兼容端点
- ✅ Anthropic Claude API
- ✅ DashScope (阿里云)
- ✅ OpenRouter

### 计划支持

- ⏳ Gemini API
- ⏳ LLaMA 本地部署
- ⏳ Ollama

---

## ⚙️ 环境变量

```bash
# 安装器
TOKEN_SAVER_BIN=~/.local/bin   # squeez 安装目录
CLAUDE_CONFIG_DIR=~/.claude    # Claude 配置目录
CODEX_HOME=~/.codex            # Codex 配置目录

# squeez 压缩策略
SQUEEZ_MAX_LINES=200
SQUEEZ_HEAD=40
SQUEEZ_TAIL=40
SQUEEZ_ERR_CONTEXT=2
```

---

## 🤝 贡献指南

欢迎提交 Issue 和 PR！优先级：

1. **Bug 修复** (P0)
2. **新工具集成** (P1)  
3. **文档完善** (P2)
4. **性能优化** (P3)

### 开发快速开始

```bash
git clone https://github.com/MySetsuna/token-saver.git
cd token-saver

pnpm test         # 运行自检（无其他依赖）
```

---

## 📄 许可证

**Apache License 2.0** — 商业友好，可自由修改和发布。

---

## 🙏 致谢

本项目汇总了以下开源项目的最佳实践：

- [claudioemmanuel/squeez](https://github.com/claudioemmanuel/squeez) — 终端压缩
- [yamadashy/repomix](https://github.com/yamadashy/repomix) — 代码打包
- [microsoft/LLMLingua](https://github.com/microsoft/LLMLingua) — 上下文压缩
- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — 文言文输出
- [sliday/tamp](https://github.com/sliday/tamp) — API 代理
- [flightlesstux/prompt-caching](https://github.com/flightlesstux/prompt-caching) — 缓存机制

---

## 📞 支持

- **Issues**: [GitHub Issues](https://github.com/MySetsuna/token-saver/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MySetsuna/token-saver/discussions)

---

**🌟 If this project saves you $$ on LLM bills, star us on GitHub!**
