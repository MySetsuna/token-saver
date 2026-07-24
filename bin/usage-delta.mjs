#!/usr/bin/env node
// usage-delta — 比较两次 token-usage --json 快照的差值（同任务装前/装后）
// 用法: node bin/usage-delta.mjs before.json after.json
import { readFileSync } from "node:fs";

const [aPath, bPath] = process.argv.slice(2);
if (!aPath || !bPath) {
  console.error("用法: node bin/usage-delta.mjs <before.json> <after.json>");
  process.exit(2);
}

const keys = ["input", "cacheRead", "cacheWrite", "output", "total"];
const a = JSON.parse(readFileSync(aPath, "utf8"));
const b = JSON.parse(readFileSync(bPath, "utf8"));

const row = (k) => {
  const av = Number(a[k] ?? 0);
  const bv = Number(b[k] ?? 0);
  const d = bv - av;
  const pct = av ? ((d / av) * 100).toFixed(1) : "n/a";
  return { k, av, bv, d, pct };
};

const rows = keys.map(row);
console.log("field\tbefore\tafter\tdelta\tdelta%");
for (const r of rows) {
  console.log(`${r.k}\t${r.av}\t${r.bv}\t${r.d}\t${r.pct}%`);
}
const tot = rows.find((r) => r.k === "total");
if (tot && tot.d < 0) {
  console.log(`\n合计 token 减少 ${-tot.d} (${(-Number(tot.pct)).toFixed(1)}%)；正确率请另测。`);
} else if (tot) {
  console.log(`\n合计 token 变化 ${tot.d} (${tot.pct}%)；负数为节省。`);
}
