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

# 一键接入 Claude Code（会自动配置 ~/.claude/settings.json）
bash install.sh --claude-code

# 或接入 Cursor
bash install.sh --cursor

# 或接入通用 OpenAI API
bash install.sh --openai-compat
```

### 2️⃣ 手动安装（高级）

```bash
# 逐个安装核心工具
pnpm install

# 启动本地压缩代理（可选）
pnpm dev
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
│  squeez     │ repomix +    │ .claude.md  │  caveman     │
│  (Bash)     │ LLMLingua    │ (缓存锚定)  │ (文言/野人)  │
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
| **squeez** | 终端输出压缩器 | 90-95% | ✅ 集成 |
| **repomix** | 代码库打包瘦身 | 50%+ | ✅ 集成 |
| **LLMLingua** | 上下文压缩 | 2x-20x | ✅ 集成 |
| **caveman** | 文言文输出 Skill | 75-85% | ✅ 可选 |
| **tamp** | API 代理 Token 去重 | 50% | ⚠️ 高级 |
| **prompt-caching** | 提示词缓存 | 50-90% | ✅ 自动 |

---

## 🚀 详细配置

### 场景 1: Claude Code 用户（最常见）

```bash
# 自动配置 ~/.claude/settings.json + .claude.md
bash install.sh --claude-code

# 验证安装成功
claude --help  # 应显示"Token Saver 已启用"
```

此时你的 Claude Code 会：
- ✅ 自动压缩终端输出（90% 减少）
- ✅ 加载缓存锚定的 Prompt 结构
- ✅ 支持 `/wenyan` 激活文言文模式
- ✅ 智能剥离代码库冗余信息

### 场景 2: 启用极致文言文模式

```bash
# 在项目根目录编辑 .claude.md
cat << 'EOF' >> .claude.md

## Token Saver: Wenyan Protocol (文言模式)

激活后 Claude 将使用古文回复，节省 50% 以上输出 Token：
- 代码块 100% 无损，仅压缩解释性文本
- 骨干技术短语保留，冗余客套话删除
- 信息密度提升 3-5 倍

模式: WENYAN_ULTRA (极致古文，字符数减少 80%)
EOF
```

### 场景 3: 集成到 CI/CD 构建流水线

```yaml
# .github/workflows/build.yml
- name: "Compress Code Context for LLM"
  run: |
    npm run compress:repo  # 自动生成 codebase.xml（瘦身 50%）
    npm run compress:logs  # 处理 build 日志（去噪 80%）
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

编辑 `config/compress-rules.json`：

```json
{
  "terminal": {
    "stripAnsi": true,
    "collapseRepeated": true,
    "maxLines": 100,
    "keepErrorContext": 3
  },
  "code": {
    "removeComments": true,
    "removeDocstrings": false,
    "astSkeletonOnly": true,
    "maxDepth": 3
  },
  "output": {
    "wenyanMode": "ultra",
    "maxLength": 500,
    "preserveCodeBlocks": true
  }
}
```

### 本地 Token 计数器

```bash
# 估算当前上下文的 Token 成本
npm run token:count

# 输出示例:
# ┌─────────────────────────────────┐
# │ Current Context Analysis        │
# ├─────────────────────────────────┤
# │ System Prompt:       2000 Token │
# │ Files included:      8500 Token │
# │ Bash output:          500 Token │
# │ Cache hits:         -1800 Token │
# │                                 │
# │ Total (estimated):  9200 Token  │
# └─────────────────────────────────┘
```

---

## 📂 项目结构

```
token-saver/
├── install.sh                 # 一键安装脚本
├── package.json               # pnpm 依赖
├── README.md                  # 本文档
├── LICENSE                    # Apache 2.0
│
├── src/
│   ├── cli/
│   │   ├── index.ts          # 命令行入口
│   │   └── commands/
│   │       ├── install.ts    # 安装命令
│   │       ├── token-count.ts
│   │       └── compress.ts
│   │
│   ├── core/
│   │   ├── squeez.ts         # 终端压缩器
│   │   ├── prompt-cacher.ts  # 缓存管理
│   │   ├── ast-minify.ts     # 代码骨架提取
│   │   └── semantic-cache.ts # 向量缓存
│   │
│   ├── integrations/
│   │   ├── claude-code.ts    # Claude Code 适配
│   │   ├── cursor.ts         # Cursor 适配
│   │   ├── aider.ts          # Aider 适配
│   │   └── openai-compat.ts  # 通用 OpenAI API
│   │
│   └── skills/
│       ├── wenyan.ts         # 文言文输出 Skill
│       ├── caveman.ts        # 野人模式
│       └── lean-prompt.ts
│
├── skills/                    # Claude Code Skills（可选安装）
│   ├── token-saver-wenyan/    # 文言文输出 Skill
│   │   ├── SKILL.md
│   │   └── prompt.md
│   └── token-saver-basic/     # 基础 Skill
│       ├── SKILL.md
│       └── prompt.md
│
├── config/
│   ├── compress-rules.json    # 压缩规则配置
│   ├── .claude.md.template    # Claude.md 模板
│   └── settings.json.template # 全局设置模板
│
├── tests/
│   ├── squeeze.test.ts
│   ├── ast-minify.test.ts
│   └── prompt-cacher.test.ts
│
└── docs/
    ├── ARCHITECTURE.md        # 详细架构文档
    ├── TROUBLESHOOTING.md     # 问题排查
    ├── BENCHMARKS.md          # 性能对比数据
    └── API.md                 # 开发者文档
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

## 📈 监控与诊断

### 实时 Token 统计

```bash
npm run token:watch

# 实时显示每次调用的 Token 消耗对比
# ┌──────────────────────────┐
# │ 🔴 WITHOUT Token Saver   │
# │ Request: 15000 Token     │
# └──────────────────────────┘
#          ↓  75% 节省
# ┌──────────────────────────┐
# │ 🟢 WITH Token Saver      │
# │ Request: 3750 Token      │
# └──────────────────────────┘
```

### 生成优化报告

```bash
npm run report:optimization

# 输出 HTML 报告: ./reports/optimization-latest.html
# - 对比: 有/无 Token Saver 的 Token 消耗
# - 热点: 哪些工具贡献了最大节省
# - 建议: 针对你的使用模式的定制优化策略
```

---

## ⚙️ 环境变量

```bash
# 启用调试日志
TOKEN_SAVER_DEBUG=1

# 指定配置文件位置
TOKEN_SAVER_CONFIG=/path/to/config.json

# 禁用特定功能（逗号分隔）
TOKEN_SAVER_DISABLE=squeez,caveman

# 文言文模式: off / basic / full / ultra
TOKEN_SAVER_WENYAN=ultra

# Semantic Cache 后端 (redis / memory / disk)
TOKEN_SAVER_CACHE_BACKEND=redis
TOKEN_SAVER_REDIS_URL=redis://localhost:6379
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
