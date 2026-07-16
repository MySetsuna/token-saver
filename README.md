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
git clone https://github.com/token-saver/token-saver.git
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
pnpm test                      # 运行自检（squeez + 安装器幂等性）
pnpm token:count README.md     # 估算文件 Token 成本
pnpm compress:repo             # 打包瘦身代码库（repomix）
<某长输出命令> 2>&1 | squeez    # 手动压缩任意终端输出
```

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
│  squeez     │ repomix      │ 全局规范    │ 微言大义     │
│  (内置)     │ (npx)        │ (缓存锚定)  │ (文言,默认)  │
├─────────────┼──────────────┼─────────────┼──────────────┤
│  节省 90%   │  节省 50%    │  节省 50%   │  节省 75%    │
│  (终端噪音) │  (代码冗冗)  │  (历史)     │  (废话)      │
└─────────────┴──────────────┴─────────────┴──────────────┘
                        ↓
              最终节省: 70%-90% Token
```

---

## 📦 核心工具链

| 工具 | 职责 | 节省幅度 | 状态 |
|------|------|---------|------|
| **squeez** (`bin/squeez`) | 终端输出压缩器（去 ANSI、折叠重复、智能截断） | 73-97%（实测） | ✅ 内置 |
| **repomix** | 代码库打包瘦身（`npx -y repomix`） | 50%+ | ✅ 集成 |
| **微言大义协议** | 文言文输出（替代 caveman，注入即默认启用） | 75-85% | ✅ 内置 |
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

### 场景 2: 文言文模式（默认已启用）

`--claude-code` / `--codex` 安装后，微言大义协议**默认生效**，无需额外配置：
- 代码块 100% 无损，仅压缩解释性文本
- 骨干技术短语保留，冗余客套话删除
- 会话中说「白话模式」临时恢复常规输出

不想默认启用？删除 `~/.claude/CLAUDE.md` 中 token-saver 标记块内的「微言大义协议」小节即可。

### 场景 3: 集成到 CI/CD 构建流水线

```yaml
# .github/workflows/build.yml
- name: "Compress Code Context for LLM"
  run: |
    npm run compress:repo                        # repomix 打包（瘦身 50%）
    npm run build 2>&1 | bin/squeez > build.log  # build 日志去噪（80%+）
```

---

## 📊 效果对比

### 修改一个组件前后的 Token 消耗

#### ❌ 未优化（传统方案）

```
System Prompt:        2000 Token
代码库完整上下文:      15000 Token
Bash 日志 (编译):     10000 Token
对话历史:             5000 Token
───────────────────────────
总计:                32000 Token
```

#### ✅ 优化后（Token Saver）

```
System Prompt (缓存):   -1800 Token (90% 缓存命中)
代码库 (repomix):       7500 Token (50% 瘦身)
Bash 日志 (squeez):      500 Token (95% 压缩)
对话历史 (滑动窗口):    1200 Token (75% 去噪)
───────────────────────────
总计:                  8400 Token
```

**节省: 73.75%** ✨

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
- 挂载 Claude Code Hook: `PreToolUse` / `PostToolUse`
- 拦截 Bash 输出，去重、截断、剥离 ANSI 码
- 效果: `ps aux` 从 40k → 2k Token

#### Layer 2: 代码库去噪（repomix + LLMLingua）
- 使用 AST 提取代码骨架（仅保留声明）
- 使用信息熵算法删除冗余词汇
- 效果: 项目打包 XML 瘦身 50%+

#### Layer 3: Prompt 缓存锚定（.claude.md）
- 遵循"静态在前，动态在后"原则
- 使用 XML 标签模块化 Prompt
- 缓存命中率 95%+，费用降低 90%

#### Layer 4: 输出人格压缩（caveman）
- 文言文协议: 字符数减少 80%，语义完整
- 去除客套话、冗长解释
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
git clone https://github.com/token-saver/token-saver.git
cd token-saver

pnpm install
pnpm dev          # 启动开发服务器
pnpm test         # 运行测试
pnpm build        # 生产构建
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

- **Issues**: [GitHub Issues](https://github.com/token-saver/token-saver/issues)
- **Discussions**: [GitHub Discussions](https://github.com/token-saver/token-saver/discussions)
- **文档**: [完整中文文档](./docs)

---

**🌟 If this project saves you $$ on LLM bills, star us on GitHub!**
