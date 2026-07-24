# 🗜️ Token Saver — 完整的 Token 节省系统

一个开源的 LLM Token 节省方案：压终端噪声、按需取上下文、稳定 prompt 前缀、约束输出与代码增量，并用 Claude Code / Codex 服务端 usage 验证真实收益。

> **适配**: Claude Code / Codex / Aider / Cursor
> **开箱即用**: 一键安装脚本，无需繁琐配置
> **诚实计量**: usage 为实测；字符估算与人工示例不作收益承诺

---

## 🎯 快速开始

### 1️⃣ 自动安装（推荐）

```bash
# 克隆项目
git clone https://github.com/MySetsuna/token-saver.git
cd token-saver

# Windows PowerShell：一键接入 Claude Code + Codex（默认）
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Windows PowerShell：或指定 Codex / Cursor / Aider
powershell -ExecutionPolicy Bypass -File .\install.ps1 --codex
powershell -ExecutionPolicy Bypass -File .\install.ps1 --cursor
powershell -ExecutionPolicy Bypass -File .\install.ps1 --aider

# macOS / Linux / Git Bash：一键接入 Claude Code + Codex
bash install.sh --all

# macOS / Linux / Git Bash：或接入 Codex CLI / Cursor / Aider
bash install.sh --codex
bash install.sh --cursor
bash install.sh --aider

# 通用 OpenAI 兼容端点优化指引
bash install.sh --openai-compat
```

所有写入均幂等（重复运行只更新 `<!-- token-saver -->` 标记块），首次修改前自动备份 `*.token-saver.bak`。

### 2️⃣ 验证与日常使用

```bash
pnpm test                      # 全量自检
pnpm token:usage --all         # 汇总本机 Claude/Codex 服务端真实 usage
pnpm token:count README.md     # 粗估文件 Token，仅供快速比较
pnpm cache:check --strict before.txt after.txt  # 验证两次 prompt 前缀逐字节一致
pnpm cache:lint config/claude-md.template       # 静态文件缓存杀手检查
pnpm pack:repo                 # 打包瘦身代码库并实测前后 token 差（L2，需联网）
<某长输出命令> 2>&1 | squeez    # 手动压缩任意终端输出
```

`token-usage` 只读 JSONL 的 usage 字段，不输出对话正文。`prompt-prefix-check` 以两次快照的真实公共前缀与 SHA-256 判定稳定性。`cache-lint` 查静态文件里易抖动的日期/UUID 等字面。

### 同任务装前/装后对比（真实 usage）

```bash
token-usage --all --json > before.json   # 或指定日志目录
# …跑同一任务集…
token-usage --all --json > after.json
pnpm token:delta before.json after.json  # 打印各字段差值；负数为节省
```

正确率须另测；delta 只报 token 量，不作收益承诺。

---

## 🏗️ 系统架构

1. **真实计量**：先看 Claude/Codex 服务端 usage，再谈收益。
2. **最小上下文**：diff → 符号关系 → `rg` → 精确行段；`repomix` 末位。
3. **确定性缓存**：静态前缀在前、动态尾部在后；两次快照逐字节验证。
4. **语义预算**：默认 terse，教学切 normal，安全/迁移/审查自动 audit。
5. **最小建造**：Ponytail 约束代码与依赖增量，安全边界不省。

终端日志另由 `squeez` 去噪。各层收益重叠，最终效果只按同任务前后 usage 计算。

---

## 📦 核心工具链

| 工具 | 职责 | 节省类型 | 状态 |
|------|------|---------|------|
| **squeez** | 终端输出压缩（去 ANSI、折叠重复、截断；错误行永留） | **确定性**（管道可复现） | ✅ 内置 |
| **token-usage** | 聚合 Claude/Codex 服务端 usage | 真实计量 | ✅ 内置 |
| **usage-delta** | 两次 usage JSON 快照差 | 真实计量辅助 | ✅ 内置 |
| **prompt-prefix-check** | 两次 prompt 前缀/hash 比较 | **确定性** | ✅ 内置 |
| **cache-lint** | 静态文件缓存杀手扫描 | **确定性** | ✅ 内置 |
| **repomix** / pack-repo | 跨模块全景末位打包 | 视仓库（可反增） | ✅ 集成 |
| **terse/normal/audit** + 文言/Caveman | 输出语义预算 | **行为性**（依模型遵从） | ✅ 内置 |
| **Ponytail** | 少写码 / 最小 diff | **行为性** | ✅ 内置 |
| **tamp** | API 输入去重（`--openai-compat` 指引） | 外部工具 | ⚠️ 可选 |

> **确定性** = 本机管道/脚本可复现；**行为性** = 依赖模型是否遵守注入规范，须用 usage+正确率同任务对照。LLMLingua 等重依赖压缩**不计划内置**（与轻量定位冲突）。

---

## 🚀 详细配置

### 场景 1: Claude Code + Codex 一键配置

```bash
# 安装三个工具，并注入 ~/.claude/CLAUDE.md 与 ~/.codex/AGENTS.md
bash install.sh --all

# 验证安装成功
echo test | squeez
token-usage --all
```

Claude Code 与 Codex 将共同采用检索优先上下文、三级输出预算、真实 usage 计量及确定性 prompt 前缀验证。Claude 的每回合提醒仅一行；旧 `bash` reminder 与字面缓存 hook 会自动迁移移除。

### 场景 2: 输出语义预算（默认已启用）

`--all` / `--claude-code` / `--codex` 安装后，按任务风险分配输出长度：

| 模式 | 触发 | 输出 |
|---|---|---|
| terse | 默认 | 结论、必要依据、下一动作 |
| normal | 用户说“白话模式”/`normal mode` | 完整清晰，仍去赘述 |
| audit | 安全、破坏性操作、迁移、审计、代码审查 | 风险、证据、验证完整保留 |

- 中文默认文言电报体（微言大义）；说「白话模式」可切 normal
- 代码、命令、错误、路径、URL 100% 原样

不想默认启用？删除全局文件 token-saver 标记块内的「输出语义预算」小节即可。

### 卸载

```bash
bash install.sh --uninstall
# 或: powershell -ExecutionPolicy Bypass -File .\install.ps1 --uninstall
```

从 `*.token-saver.bak` 恢复已改配置，并移除 Claude reminder 文件。`~/.local/bin` 下的 squeez 等工具需手动删除。

### 代码建造精简（Ponytail 协议，默认已启用）

前面几层压缩「怎么说」，这一层管「造什么」——**少写代码本身就是省 token**：写出来的每一行都要在当下生成、日后反复进上下文。`--claude-code` / `--codex` / `--cursor` / `--aider` 安装后随规范一并注入，与输出人格路由正交、同为默认开启。

核心是一把「懒梯子」，改动前先读懂问题，止于**首个成立之档**：

> YAGNI（臆测需求即跳过）→ 复用本仓已有 → 标准库 → 平台原生特性 → 已装依赖 → 一行搞定 → 方才最小实现

- 不做未经请求的抽象（无单实现的接口、单产物的工厂、恒定值的配置）
- 最短可用 diff 取胜；改 bug 修根因（先 grep 全部调用方，共有函数处一次修好）
- **绝不简化掉**：输入校验、防丢数据的错误处理、安全措施、无障碍基础、用户明确要求之物
- Claude 每回合仅注入一行抗漂移提醒；说 `stop ponytail` 临时停用

### 场景 3: 集成到 CI/CD 构建流水线

```yaml
# .github/workflows/build.yml
- name: "Compress Code Context for LLM"
  run: |
    npm run compress:repo                        # repomix 打包（瘦身 50%）
    npm run build 2>&1 | bin/squeez > build.log  # build 日志去噪（80%+）
```

---

## 📊 效果对比（本地估算基准，可复现）

`pnpm bench` 用统一字符公式作快速相对比较：压缩行为可复现，token 数仍属估算；输出层另受模型遵从与正确率影响。真实成本请以 `token-usage --all` 为准。

```bash
pnpm bench          # 人读表格
pnpm bench --md     # 输出 markdown
```

<!-- token-saver:bench:begin -->
**终端压缩（行为确定性，token 数为本地估算）**

| 场景 | 原始 Token | 优化后 Token | 节省 |
|------|-----------:|-------------:|-----:|
| 依赖安装日志 | 3093 | 617 | **80%** |
| 构建编译日志 | 8715 | 977 | **88%** |
| 测试运行输出 | 5613 | 510 | **90%** |
| **终端三项合计** | **17421** | **2104** | **87%** |

**输出层（人工样例·估算，不作收益承诺）**

| 协议 | 原始 Token | 优化后 Token | 节省 |
|------|-----------:|-------------:|-----:|
| 技术骨架体（4 例合计） | 261 | 127 | **51%** |
| Caveman（3 例合计） | 113 | 44 | **61%** |
| Ponytail 建造精简（示例） | 68 | 6 | **91%** |
<!-- token-saver:bench:end -->

> 基准内含承诺校验：压缩后若 `WARNING` / `FAIL` 行丢失则直接失败退出——**错误行永不被压掉**。

### 人工输出样例（同一问，两种写法）

此类例子只说明短写法字符更少，不证明真实会话成本或语义等价。应在固定任务集上对比服务端 usage 与正确率。

---

## 🛠️ 高级用法

### 自定义压缩策略

squeez 通过环境变量配置：

```bash
SQUEEZ_MAX_LINES=200    # 超过此行数才截断（默认 200）
SQUEEZ_HEAD=40          # 截断时保留的开头行数
SQUEEZ_TAIL=40          # 截断时保留的结尾行数
SQUEEZ_ERR_CONTEXT=2    # 错误行上下文保留行数（错误行永远保留）
SQUEEZ_JSON_MAX=0       # >0 时截断超长单行 JSON（以 { 或 [ 开头）；默认关
```

### 本地 Token 计数器

```bash
# 估算文件或管道内容的 Token 成本（CJK ≈ 1 token/字，其余 ≈ 4 字符/token）
npm run token:count README.md
cat build.log | node bin/token-count.mjs

# 输出示例:
# chars: 12143  est. tokens: 6890
```

### 服务端 Usage 与 Prompt 前缀

```bash
token-usage --all                 # 自动读取 Claude/Codex 本机 JSONL，仅汇总 usage
token-usage --claude --json       # 只看 Claude，机器可读
token-usage ./captured-logs       # 汇总指定文件或目录

prompt-prefix-check --strict first.txt second.txt
prompt-prefix-check --min-prefix 4096 first.txt second.txt
```

---

## 📂 项目结构

```
token-saver/
├── install.sh / install.ps1          # 一键安装（幂等备份；--uninstall 可回滚）
├── bin/
│   ├── squeez                        # 终端压缩（bash+awk）
│   ├── token-count.mjs / token-usage.mjs / usage-delta.mjs
│   ├── prompt-prefix-check.mjs / cache-lint.mjs
│   └── pack-repo.sh
├── config/                           # 各平台注入模板 + reminder hook
├── bench/run.sh                      # 本地可复现基准
├── tests/test-squeez.sh              # 全量自检
└── LICENSE                           # Apache 2.0
```

---

## 🎓 原理深度解析

### 五项协同架构

#### Layer 1: 终端输入压缩（squeez）
- 全局规范驱动：长输出命令自动追加 `| squeez` 管道
- 剥离 ANSI 码、折叠重复行、智能截断（错误行永远保留）
- 效果: 实测 73-97% 压缩

#### Layer 2: 检索优先上下文
- diff、符号关系、`rg`、精确行段依次取用
- `repomix` 仅用于限定范围的跨模块全景

#### Layer 3: Prompt 前缀稳定
- 静态在前，动态在后
- 两次快照逐字节比较，不按日期/UUID 等字面臆测

#### Layer 4: 输出语义预算
- 默认 terse；教学 normal；安全/迁移/审查 audit
- 中文文言电报体 / 英文 Caveman；代码与报错原样

#### Layer 5: 最小建造 + 真实计量
- Ponytail 约束代码增量；`token-usage` / `usage-delta` 做同任务对照

---

## 🔌 适配平台

- ✅ Claude Code · Codex · Cursor · Aider · RidgeCode
- ✅ OpenAI 兼容端点指引（`--openai-compat`，含可选 tamp）
- 运行时 JSON/RAG 极重：可**并列** [Headroom](https://github.com/headroomlabs-ai/headroom)（`headroom wrap`），非本仓依赖

---

## ⚙️ 环境变量

```bash
TOKEN_SAVER_BIN=~/.local/bin
CLAUDE_CONFIG_DIR=~/.claude
CODEX_HOME=~/.codex

SQUEEZ_MAX_LINES=200
SQUEEZ_HEAD=40
SQUEEZ_TAIL=40
SQUEEZ_ERR_CONTEXT=2
SQUEEZ_JSON_MAX=0
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
- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — terse English 灵感
- [sliday/tamp](https://github.com/sliday/tamp) — API 代理（可选）
- [flightlesstux/prompt-caching](https://github.com/flightlesstux/prompt-caching) — 缓存机制

---

## 📞 支持

- **Issues**: [GitHub Issues](https://github.com/MySetsuna/token-saver/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MySetsuna/token-saver/discussions)

---

**🌟 If this project saves you $$ on LLM bills, star us on GitHub!**
