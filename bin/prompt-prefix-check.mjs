#!/usr/bin/env node
// 比较两次 prompt 快照：报告稳定公共前缀、首个差异位置与各自 SHA-256。
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

const args = process.argv.slice(2);
if (args.includes("--help") || args.includes("-h")) {
  console.log(`用法: prompt-prefix-check [--strict] [--min-prefix 字节数] [--json] <首次快照> <再次快照>

--strict 要求完全一致；--min-prefix 允许动态尾部，但公共前缀不得短于指定字节数。`);
  process.exit(0);
}
const json = args.includes("--json");
const strict = args.includes("--strict");
const minAt = args.indexOf("--min-prefix");
const minPrefix = minAt >= 0 ? Number(args[minAt + 1]) : 0;
const skip = new Set(["--json", "--strict"]);
if (minAt >= 0) { skip.add("--min-prefix"); skip.add(args[minAt + 1]); }
const files = args.filter((arg) => !skip.has(arg));

if (files.length !== 2 || !Number.isInteger(minPrefix) || minPrefix < 0) {
  console.error("用法: prompt-prefix-check [--strict] [--min-prefix 字节数] [--json] <首次快照> <再次快照>");
  process.exit(2);
}

const [a, b] = files.map((file) => readFileSync(file));
let stableBytes = 0;
const limit = Math.min(a.length, b.length);
while (stableBytes < limit && a[stableBytes] === b[stableBytes]) stableBytes++;

const identical = a.length === b.length && stableBytes === a.length;
const before = a.subarray(0, stableBytes).toString("utf8");
const lines = before.split("\n");
const sha256 = (value) => createHash("sha256").update(value).digest("hex");
const result = {
  identical,
  stableBytes,
  firstDifference: identical ? null : { byte: stableBytes + 1, line: lines.length, column: lines.at(-1).length + 1 },
  firstBytes: a.length,
  secondBytes: b.length,
  firstSha256: sha256(a),
  secondSha256: sha256(b),
  requiredStableBytes: strict ? Math.max(a.length, b.length) : minPrefix,
};
result.pass = strict ? identical : stableBytes >= minPrefix;

if (json) {
  console.log(JSON.stringify(result, null, 2));
} else if (identical) {
  console.log(`PASS: prompt 前缀完全一致（${stableBytes} bytes，sha256 ${result.firstSha256}）`);
} else {
  console.log(`${result.pass ? "PASS" : "FAIL"}: 稳定公共前缀 ${stableBytes} bytes；首差 byte ${result.firstDifference.byte}，L${result.firstDifference.line}:C${result.firstDifference.column}`);
  console.log(`首次 sha256 ${result.firstSha256}`);
  console.log(`再次 sha256 ${result.secondSha256}`);
}
process.exit(result.pass ? 0 : 1);
