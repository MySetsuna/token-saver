#!/usr/bin/env node
// cache-lint — 扫描静态 prompt 文件中的「缓存杀手」（易导致前缀逐字节抖动）
// 用法: node bin/cache-lint.mjs <文件...>
//       node bin/cache-lint.mjs --fix [--write] <文件...>
// 命中即 exit 1；--fix 默认 stdout 预览，--fix --write 就地改并备份 *.cache-lint.bak
import { readFileSync, writeFileSync, copyFileSync, existsSync } from "node:fs";

const PLACEHOLDER = "⟨removed⟩";

// 故意只抓「运行时会变」的形态；规范文中的「日期/UUID」字样不命中
const RULES = [
  { name: "iso-date", re: /\b20\d{2}-\d{2}-\d{2}\b/g },
  { name: "clock", re: /\b(?:[01]?\d|2[0-3]):[0-5]\d:[0-5]\d\b/g },
  { name: "uuid", re: /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/gi },
  { name: "long-hex", re: /\b[0-9a-f]{32,}\b/gi },
  { name: "home-path", re: /(?:\/Users\/[^/\s"'`]+|\/home\/[^/\s"'`]+|[A-Za-z]:\\Users\\[^\\\s"'`]+)/g },
  { name: "Date.now", re: /\bDate\.now\s*\(/g },
  { name: "new-Date", re: /\bnew\s+Date\s*\(/g },
];

function scanLine(line, lineNo) {
  const hits = [];
  for (const { name, re } of RULES) {
    re.lastIndex = 0;
    if (re.test(line)) hits.push({ lineNo, name, line });
  }
  return hits;
}

function fixText(text) {
  let out = text;
  for (const { re } of RULES) {
    re.lastIndex = 0;
    out = out.replace(re, PLACEHOLDER);
  }
  return out;
}

const args = process.argv.slice(2);
const fix = args.includes("--fix");
const write = args.includes("--write");
const files = args.filter((a) => !a.startsWith("--"));

if (!files.length) {
  console.error("用法: node bin/cache-lint.mjs [--fix [--write]] <文件...>");
  process.exit(2);
}

let dirty = false;
for (const file of files) {
  if (!existsSync(file)) {
    console.error(`cache-lint: 文件不存在: ${file}`);
    process.exit(2);
  }
  const text = readFileSync(file, "utf8");
  const lines = text.split(/\r?\n/);
  const hits = [];
  lines.forEach((line, i) => hits.push(...scanLine(line, i + 1)));

  if (!fix) {
    for (const h of hits) {
      console.error(`${file}:${h.lineNo}: [${h.name}] ${h.line.trim().slice(0, 120)}`);
      dirty = true;
    }
    continue;
  }

  const fixed = fixText(text);
  if (write) {
    if (fixed !== text) {
      copyFileSync(file, `${file}.cache-lint.bak`);
      writeFileSync(file, fixed);
      console.error(`cache-lint: 已写回 ${file}（备份 ${file}.cache-lint.bak）`);
    } else {
      console.error(`cache-lint: ${file} 无需修改`);
    }
  } else {
    process.stdout.write(fixed);
  }
}

if (!fix && dirty) process.exit(1);
