#!/usr/bin/env node
// cache-lint — 缓存锚定检查器（L3）：扫描入缓存的静态文件，命中「缓存杀手」即报错退 1
// 动态内容（时间戳、绝对家目录、UUID/哈希、运行时取时）混入静态区会使 prompt cache 每次失配。
// 用法:
//   node bin/cache-lint.mjs <文件...>              检查，命中即 exit 1
//   node bin/cache-lint.mjs --fix <文件>           剥离缓存杀手，输出到 stdout（预览，不改文件）
//   node bin/cache-lint.mjs --fix --write <文件...> 就地剥离并备份 *.cache-lint.bak
import { readFileSync, writeFileSync, copyFileSync } from "node:fs";

// [正则, 说明]；逐行匹配，命中即为缓存杀手
const RULES = [
  [/\b\d{4}-\d{2}-\d{2}\b/, "日期 YYYY-MM-DD"],
  [/\b\d{1,2}:\d{2}:\d{2}\b/, "时钟 HH:MM:SS"],
  [/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i, "UUID"],
  [/\b[0-9a-fA-F]{32,}\b/, "长 hex/哈希"],
  [/(?:\/Users\/|\/home\/|[A-Za-z]:\\Users\\)[^\s"'`]+/, "绝对家目录路径"],
  [/\bDate\.now\s*\(|\bnew\s+Date\s*\(/, "运行时取时调用"],
];
const PLACEHOLDER = "⟨removed⟩"; // 中性占位，本身不含任何缓存杀手，故 --fix 后再 lint 必净

// 扫描文本，返回命中数组 [{line, why, match}]
function scan(text) {
  const hits = [];
  text.split(/\r?\n/).forEach((line, i) => {
    for (const [re, why] of RULES) {
      const m = line.match(re);
      if (m) hits.push({ line: i + 1, why, match: m[0] });
    }
  });
  return hits;
}

// 把每处缓存杀手替换为占位，返回 {out, n}
function fixText(text) {
  let out = text, n = 0;
  for (const [re] of RULES) {
    const g = new RegExp(re.source, re.flags.includes("g") ? re.flags : re.flags + "g");
    out = out.replace(g, () => { n++; return PLACEHOLDER; });
  }
  return { out, n };
}

const args = process.argv.slice(2);
const fix = args.includes("--fix");
const write = args.includes("--write");
const files = args.filter((a) => !a.startsWith("--"));

if (!files.length) {
  console.error("用法: node bin/cache-lint.mjs [--fix [--write]] <文件...>");
  process.exit(2);
}

if (fix) {
  if (!write) {
    if (files.length !== 1) {
      console.error("❌ 预览模式仅支持单文件；多文件请加 --write 就地修改");
      process.exit(2);
    }
    const { out, n } = fixText(readFileSync(files[0], "utf8"));
    process.stdout.write(out);
    process.stderr.write(`\n✅ 剥离 ${n} 处缓存杀手（预览，未写回；加 --write 就地修改）\n`);
    process.exit(0);
  }
  let total = 0;
  for (const f of files) {
    let text;
    try { text = readFileSync(f, "utf8"); } catch { console.error(`⚠️  跳过（读不了）: ${f}`); continue; }
    const { out, n } = fixText(text);
    if (n) {
      copyFileSync(f, f + ".cache-lint.bak");
      writeFileSync(f, out);
      total += n;
      console.log(`  ${f}: 剥离 ${n} 处 → 备份 ${f}.cache-lint.bak`);
    } else {
      console.log(`  ${f}: 无需修改`);
    }
  }
  console.log(`✅ 共剥离 ${total} 处缓存杀手`);
  process.exit(0);
}

// 默认：检查并报告
let violations = 0;
for (const f of files) {
  let text;
  try { text = readFileSync(f, "utf8"); } catch { console.error(`⚠️  跳过（读不了）: ${f}`); continue; }
  for (const h of scan(text)) {
    violations++;
    console.log(`${f}:${h.line}: 缓存杀手[${h.why}]: ${h.match}`);
  }
}

if (violations) {
  console.log(`\n❌ 命中 ${violations} 处缓存杀手——静态区应剥离动态内容以保 prompt cache 命中（可 --fix 自动剥离）`);
  process.exit(1);
}
console.log(`✅ ${files.length} 个文件干净，无缓存杀手`);
