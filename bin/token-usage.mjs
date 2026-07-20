#!/usr/bin/env node
// 汇总 Claude Code / Codex JSONL 中服务端返回的真实 token usage；不读取或输出对话正文。
import { createReadStream, existsSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { createInterface } from "node:readline";

const args = process.argv.slice(2);
const json = args.includes("--json");
const help = args.includes("--help") || args.includes("-h");
const explicit = args.filter((arg) => !arg.startsWith("--"));
const useClaude = args.includes("--claude") || args.includes("--all") || args.length === 0;
const useCodex = args.includes("--codex") || args.includes("--all") || args.length === 0;

if (help) {
  console.log(`用法: token-usage [--all|--claude|--codex] [--json] [JSONL 文件/目录...]

无参数等同 --all。计数来自服务端 usage 字段；不估算、不输出对话正文。`);
  process.exit(0);
}

const roots = [...explicit];
if (useClaude) roots.push(join(homedir(), ".claude", "projects"));
if (useCodex) roots.push(join(homedir(), ".codex", "sessions"));

function collect(path, out) {
  if (!existsSync(path)) return;
  const full = resolve(path);
  if (statSync(full).isFile()) {
    if (full.endsWith(".jsonl") || explicit.some((item) => resolve(item) === full)) out.add(full);
    return;
  }
  for (const entry of readdirSync(full, { withFileTypes: true })) {
    const child = join(full, entry.name);
    if (entry.isDirectory()) collect(child, out);
    else if (entry.isFile() && entry.name.endsWith(".jsonl")) out.add(child);
  }
}

const files = new Set();
for (const root of roots) collect(root, files);
if (!files.size) {
  console.error("未找到 JSONL usage 日志。");
  process.exit(2);
}

const zero = () => ({ input: 0, cacheRead: 0, cacheWrite: 0, output: 0, reasoning: 0, total: 0, requests: 0 });
const num = (value) => Number.isFinite(Number(value)) ? Number(value) : 0;
const add = (to, from) => {
  for (const key of Object.keys(to)) to[key] += num(from[key]);
};

function normalizeUsage(usage) {
  if (!usage || typeof usage !== "object") return null;
  if (usage.total_token_usage) return normalizeUsage(usage.total_token_usage);

  const anthropic = "cache_creation_input_tokens" in usage || "cache_read_input_tokens" in usage;
  const openai = "prompt_tokens" in usage || "completion_tokens" in usage;
  if (!anthropic && !openai && !("input_tokens" in usage || "output_tokens" in usage || "total_tokens" in usage)) return null;

  const input = num(usage.input_tokens ?? usage.prompt_tokens);
  const cacheRead = num(usage.cache_read_input_tokens ?? usage.cached_input_tokens ?? usage.prompt_tokens_details?.cached_tokens);
  const cacheWrite = num(usage.cache_creation_input_tokens ?? usage.cache_write_input_tokens);
  const output = num(usage.output_tokens ?? usage.completion_tokens);
  const reasoning = num(usage.reasoning_output_tokens ?? usage.completion_tokens_details?.reasoning_tokens);
  const total = num(usage.total_tokens) || (anthropic ? input + cacheRead + cacheWrite + output : input + output);
  return { input, cacheRead, cacheWrite, output, reasoning, total, requests: 1 };
}

async function readUsage(file) {
  const sum = zero();
  let codexTotal = null;
  const lines = createInterface({ input: createReadStream(file, "utf8"), crlfDelay: Infinity });
  for await (const line of lines) {
    let event;
    try { event = JSON.parse(line); } catch { continue; }

    const info = event?.payload?.info;
    if (info?.total_token_usage) {
      codexTotal = normalizeUsage(info.total_token_usage);
      continue;
    }

    const usage = event?.usage ?? event?.message?.usage ?? event?.response?.usage ?? event?.payload?.usage;
    const normalized = normalizeUsage(usage);
    if (normalized) add(sum, normalized);
  }
  if (codexTotal) return { ...codexTotal, requests: 1 };
  return sum;
}

const total = zero();
let sessions = 0;
for (const file of files) {
  const usage = await readUsage(file);
  if (usage.requests) sessions++;
  add(total, usage);
}

const result = { files: files.size, sessions, ...total };
if (json) {
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log(`来源文件: ${result.files}  有 usage 会话: ${result.sessions}  请求/会话计数: ${result.requests}`);
  console.log(`输入: ${result.input}  缓存读: ${result.cacheRead}  缓存写: ${result.cacheWrite}`);
  console.log(`输出: ${result.output}  推理输出: ${result.reasoning}  总计: ${result.total}`);
}
