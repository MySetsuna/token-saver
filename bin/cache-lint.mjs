#!/usr/bin/env node
// cache-lint — 缓存锚定检查器（L3）：扫描入缓存的静态文件，命中「缓存杀手」即报错退 1
// 动态内容（时间戳、绝对家目录、UUID/哈希、运行时取时）混入静态区会使 prompt cache 每次失配。
// 用法: node bin/cache-lint.mjs <文件...>   例: node bin/cache-lint.mjs ~/.claude/CLAUDE.md config/*.template
import { readFileSync } from "node:fs";

// [正则, 说明]；逐行匹配，命中即为缓存杀手
const RULES = [
  [/\b\d{4}-\d{2}-\d{2}\b/, "日期 YYYY-MM-DD"],
  [/\b\d{1,2}:\d{2}:\d{2}\b/, "时钟 HH:MM:SS"],
  [/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i, "UUID"],
  [/\b[0-9a-fA-F]{32,}\b/, "长 hex/哈希"],
  [/(?:\/Users\/|\/home\/|[A-Za-z]:\\Users\\)[^\s"'`]+/, "绝对家目录路径"],
  [/\bDate\.now\s*\(|\bnew\s+Date\s*\(/, "运行时取时调用"],
];

const files = process.argv.slice(2);
if (!files.length) {
  console.error("用法: node bin/cache-lint.mjs <文件...>");
  process.exit(2);
}

let violations = 0;
for (const f of files) {
  let text;
  try {
    text = readFileSync(f, "utf8");
  } catch (e) {
    console.error(`⚠️  跳过（读不了）: ${f}`);
    continue;
  }
  text.split(/\r?\n/).forEach((line, i) => {
    for (const [re, why] of RULES) {
      const m = line.match(re);
      if (m) {
        violations++;
        console.log(`${f}:${i + 1}: 缓存杀手[${why}]: ${m[0]}`);
      }
    }
  });
}

if (violations) {
  console.log(`\n❌ 命中 ${violations} 处缓存杀手——静态区应剥离动态内容以保 prompt cache 命中`);
  process.exit(1);
}
console.log(`✅ ${files.length} 个文件干净，无缓存杀手`);
