#!/usr/bin/env node
// cache-lint-hook — PreToolUse 警告钩子（只警告，绝不拦截）
// 当 Write/Edit 目标是「入缓存的静态配置文件」（CLAUDE.md / AGENTS.md / .cursorrules 或 .claude/ 下），
// 且写入内容含缓存杀手（时间戳/UUID/绝对家目录/运行时取时…）时，向 stderr 打印一条提醒。
// 恒 exit 0：不阻断任何写入。规则须与 bin/cache-lint.mjs 保持一致。
import { readFileSync } from "node:fs";

const RULES = [
  [/\b\d{4}-\d{2}-\d{2}\b/, "日期 YYYY-MM-DD"],
  [/\b\d{1,2}:\d{2}:\d{2}\b/, "时钟 HH:MM:SS"],
  [/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i, "UUID"],
  [/\b[0-9a-fA-F]{32,}\b/, "长 hex/哈希"],
  [/(?:\/Users\/|\/home\/|[A-Za-z]:\\Users\\)[^\s"'`]+/, "绝对家目录路径"],
  [/\bDate\.now\s*\(|\bnew\s+Date\s*\(/, "运行时取时调用"],
];

// 入缓存的静态文件：基名精确匹配，或路径位于 .claude 配置目录下
function isCachedStatic(fp) {
  if (!fp) return false;
  const base = fp.split(/[\\/]/).pop();
  if (base === "CLAUDE.md" || base === "AGENTS.md" || base === ".cursorrules") return true;
  return /[\\/]\.claude[\\/]/.test(fp);
}

let raw = "";
try { raw = readFileSync(0, "utf8"); } catch { process.exit(0); }
let ev;
try { ev = JSON.parse(raw); } catch { process.exit(0); }

const ti = ev.tool_input || {};
const fp = ti.file_path || "";
if (!isCachedStatic(fp)) process.exit(0);

// Write 取 content；Edit 取 new_string；MultiEdit 等暂不处理
const content = ti.content ?? ti.new_string ?? "";
if (!content) process.exit(0);

const hits = [];
content.split(/\r?\n/).forEach((line, i) => {
  for (const [re, why] of RULES) {
    const m = line.match(re);
    if (m) hits.push(`  L${i + 1} [${why}]: ${m[0]}`);
  }
});

if (hits.length) {
  process.stderr.write(
    `⚠️  [token-saver cache-lint] 写入 ${fp} 的内容含缓存杀手（会使 prompt cache 失配）：\n` +
    hits.slice(0, 10).join("\n") +
    "\n（仅警告，未阻断；静态区宜剥离动态内容）\n"
  );
}
process.exit(0); // 恒 0：绝不阻断写入
