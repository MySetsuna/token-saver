#!/usr/bin/env node
// token-count — 本地 Token 估算：CJK ≈ 1 token/字，其余 ≈ 4 字符/token
// 用法: node bin/token-count.mjs <文件...>  或  <命令> | node bin/token-count.mjs
import { readFileSync } from "node:fs";

const files = process.argv.slice(2);
const text = files.length
  ? files.map((f) => readFileSync(f, "utf8")).join("")
  : readFileSync(0, "utf8");

const cjk = (text.match(/[　-鿿豈-﫿]/g) || []).length;
const tokens = Math.round(cjk + (text.length - cjk) / 4);
console.log(`chars: ${text.length}  est. tokens: ${tokens}`);
