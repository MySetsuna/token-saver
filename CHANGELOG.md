# Changelog


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
