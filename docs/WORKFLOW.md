# NotebookLM 迭代工作流（token-saver 适配）

> 通用方法论见 `notebooklm-iteration-loop` skill。本文件只记本仓落地细节。

## 确定性验证命令（checker）

- test: `pnpm test`（或 `bash tests/test-squeez.sh`）
- 可选：`pnpm bench`（无网络基准，不进默认闸）
- 可选：`pnpm cache:lint config/*.template`

以上默认闸 `pnpm test` 全绿才能进入 NotebookLM 环节。

## codegraph 索引范围

- 索引根目录：仓库根 `C:\code\token-saver`
- 主要可解析：`bin/*.mjs`、`config/*.mjs`（bash/`squeez` 以源码阅读补）
- 首次：`codegraph init -i`；日常：`codegraph sync`

## NotebookLM 笔记本

- notebook_id：`c8ef3e72-7ef7-476f-b2d5-cc3a681a6267`
- 标题：token节省之道
- 状态文档来源名：`PROJECT-STATE`（来源恒 1 份）

## 目录落点

- `docs/PROJECT-STATE.md` — 唯一上传 NotebookLM
- `docs/LOG.md` — 全局 append-only
- `docs/iterations/` — 合同/报告/指导（仅本地）
