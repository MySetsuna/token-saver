#!/usr/bin/env node
// 汇总 Claude Code / Codex JSONL 的服务端 usage；只读计量字段，不读取或输出对话正文。
import { createReadStream, existsSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join, resolve } from "node:path";
import { createInterface } from "node:readline";

const args = process.argv.slice(2);
const booleanFlags = new Set(["--json", "--sessions", "--all", "--claude", "--codex", "--help", "-h"]);
const numberRules = new Map([
  ["--min-cache-hit", { min: 0, max: 100 }],
  ["--max-cache-write", { min: 0 }],
  ["--max-input-per-request", { min: 0 }],
  ["--max-cache-read-per-request", { min: 0 }],
  ["--cost-usd", { min: 0 }],
  ["--changed-lines", { min: 0, integer: true }],
  ["--quality-exit", { min: 0, max: 255, integer: true }],
]);

const help = args.includes("--help") || args.includes("-h");
if (help) {
  console.log(`用法: token-usage [--all|--claude|--codex] [--json] [--sessions] [JSONL 文件/目录...]

真实计量:
  --sessions                         输出逐会话账本（仅文件名，不含绝对路径/正文）
  --min-cache-hit PCT                总缓存命中率低于阈值则 exit 1
  --max-cache-write TOKENS           总缓存写入高于阈值则 exit 1
  --max-input-per-request TOKENS     单请求 accounted input 峰值越界则 exit 1
  --max-cache-read-per-request TOKENS 单请求 cache read 峰值越界则 exit 1

可选产出证据（不提供则保持 unknown）:
  --cost-usd N       用户确认的实际成本
  --changed-lines N  外部 diff 统计的新增+删除行
  --quality-exit N   外部测试/质量闸退出码

无平台参数时等同 --all。缓存比例按 provider 口径计算；不估价，不从 output/reasoning 猜代码量或质量。`);
  process.exit(0);
}

const values = new Map();
const explicit = [];
for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (booleanFlags.has(arg)) continue;
  if (numberRules.has(arg)) {
    const raw = args[++i];
    const value = Number(raw);
    const rule = numberRules.get(arg);
    if (raw === undefined || !Number.isFinite(value) || value < rule.min
      || (rule.max !== undefined && value > rule.max) || (rule.integer && !Number.isInteger(value))) {
      console.error(`参数错误: ${arg} 需要 ${rule.integer ? "整数" : "数字"}，范围 ${rule.min}..${rule.max ?? "∞"}`);
      process.exit(2);
    }
    values.set(arg, value);
    continue;
  }
  if (arg.startsWith("--") || arg === "-h") {
    console.error(`未知参数: ${arg}`);
    process.exit(2);
  }
  explicit.push(arg);
}

const json = args.includes("--json");
const showSessions = args.includes("--sessions");
const providerSelected = args.includes("--all") || args.includes("--claude") || args.includes("--codex");
const useDefaults = !providerSelected && explicit.length === 0;
const useClaude = args.includes("--claude") || args.includes("--all") || useDefaults;
const useCodex = args.includes("--codex") || args.includes("--all") || useDefaults;

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

const sumFields = ["input", "cacheRead", "cacheWrite", "output", "reasoning", "total", "accountedInput", "requests"];
const zero = () => Object.fromEntries(sumFields.map((key) => [key, 0]));
const emptyPeaks = () => ({ accountedInput: 0, cacheRead: 0, cacheWrite: 0 });
const num = (value) => Number.isFinite(Number(value)) ? Number(value) : 0;
const add = (to, from) => {
  for (const key of sumFields) to[key] += num(from[key]);
};
const updatePeaks = (peaks, usage) => {
  peaks.accountedInput = Math.max(peaks.accountedInput, usage.accountedInput);
  peaks.cacheRead = Math.max(peaks.cacheRead, usage.cacheRead);
  peaks.cacheWrite = Math.max(peaks.cacheWrite, usage.cacheWrite);
};

function normalizeUsage(usage) {
  if (!usage || typeof usage !== "object") return null;
  if (usage.total_token_usage) return normalizeUsage(usage.total_token_usage);

  const anthropic = "cache_creation_input_tokens" in usage || "cache_read_input_tokens" in usage;
  const openai = "prompt_tokens" in usage || "completion_tokens" in usage
    || "cached_input_tokens" in usage || "prompt_tokens_details" in usage;
  const generic = "input_tokens" in usage || "output_tokens" in usage || "total_tokens" in usage;
  if (!anthropic && !openai && !generic) return null;

  const input = num(usage.input_tokens ?? usage.prompt_tokens);
  const cacheRead = num(usage.cache_read_input_tokens ?? usage.cached_input_tokens
    ?? usage.prompt_tokens_details?.cached_tokens);
  const cacheWrite = num(usage.cache_creation_input_tokens ?? usage.cache_write_input_tokens);
  const output = num(usage.output_tokens ?? usage.completion_tokens);
  const reasoning = num(usage.reasoning_output_tokens ?? usage.completion_tokens_details?.reasoning_tokens);
  // Anthropic 将 direct/cache read/cache write 分列；OpenAI/Codex 的 cached tokens 是 input 子集。
  const accountedInput = anthropic ? input + cacheRead + cacheWrite : input;
  const total = num(usage.total_tokens) || accountedInput + output;
  return {
    input, cacheRead, cacheWrite, output, reasoning, total, accountedInput,
    provider: anthropic ? "anthropic" : openai ? "openai" : "generic",
  };
}

function ratio(part, whole) {
  return whole > 0 ? Number(((part / whole) * 100).toFixed(2)) : null;
}

function metrics(usage, requestCountKnown, peaks) {
  const requests = usage.requests;
  return {
    cacheHitPct: ratio(usage.cacheRead, usage.accountedInput),
    cacheWritePct: ratio(usage.cacheWrite, usage.accountedInput),
    reasoningPct: ratio(usage.reasoning, usage.output),
    contextFloorProxyAvg: requestCountKnown && requests ? Math.round(usage.cacheRead / requests) : null,
    accountedInputAvgPerRequest: requestCountKnown && requests ? Math.round(usage.accountedInput / requests) : null,
    accountedInputPeakPerRequest: requestCountKnown ? peaks.accountedInput : null,
    cacheReadPeakPerRequest: requestCountKnown ? peaks.cacheRead : null,
    cacheWritePeakPerRequest: requestCountKnown ? peaks.cacheWrite : null,
  };
}

async function readUsage(file) {
  const sum = zero();
  const peaks = emptyPeaks();
  const providers = new Set();
  let codexTotal = null;
  let codexRequests = 0;

  const lines = createInterface({ input: createReadStream(file, "utf8"), crlfDelay: Infinity });
  for await (const line of lines) {
    let event;
    try { event = JSON.parse(line); } catch { continue; }

    const info = event?.payload?.info;
    if (info?.total_token_usage) {
      codexTotal = normalizeUsage(info.total_token_usage);
      const last = normalizeUsage(info.last_token_usage);
      if (last) {
        codexRequests++;
        updatePeaks(peaks, last);
      }
      continue;
    }

    const usage = event?.usage ?? event?.message?.usage ?? event?.response?.usage ?? event?.payload?.usage;
    const normalized = normalizeUsage(usage);
    if (normalized) {
      providers.add(normalized.provider);
      add(sum, { ...normalized, requests: 1 });
      updatePeaks(peaks, normalized);
    }
  }

  if (codexTotal) {
    const requestsKnown = codexRequests > 0;
    const usage = { ...zero(), ...codexTotal, requests: requestsKnown ? codexRequests : 1 };
    return { usage, provider: "codex", requestCountKnown: requestsKnown, peaks };
  }

  const provider = providers.size === 1 ? [...providers][0] : providers.size ? "mixed" : "unknown";
  return { usage: sum, provider, requestCountKnown: sum.requests > 0, peaks };
}

const total = zero();
const aggregatePeaks = emptyPeaks();
const sessionRecords = [];
let sessions = 0;
let allRequestCountsKnown = true;

for (const file of files) {
  const record = await readUsage(file);
  if (!record.usage.requests) continue;
  sessions++;
  add(total, record.usage);
  if (!record.requestCountKnown) allRequestCountsKnown = false;
  else {
    aggregatePeaks.accountedInput = Math.max(aggregatePeaks.accountedInput, record.peaks.accountedInput);
    aggregatePeaks.cacheRead = Math.max(aggregatePeaks.cacheRead, record.peaks.cacheRead);
    aggregatePeaks.cacheWrite = Math.max(aggregatePeaks.cacheWrite, record.peaks.cacheWrite);
  }
  sessionRecords.push({
    source: basename(file),
    ...record.usage,
    provider: record.provider,
    requestCountKnown: record.requestCountKnown,
    metrics: metrics(record.usage, record.requestCountKnown, record.peaks),
  });
}

sessionRecords.sort((a, b) => b.accountedInput - a.accountedInput || a.source.localeCompare(b.source));
const aggregateMetrics = metrics(total, allRequestCountsKnown, aggregatePeaks);
const evidence = {
  costUsd: values.get("--cost-usd") ?? null,
  changedLines: values.get("--changed-lines") ?? null,
  qualityExit: values.get("--quality-exit") ?? null,
};
evidence.qualityPassed = evidence.qualityExit === null ? null : evidence.qualityExit === 0;
evidence.costPerChangedLine = evidence.costUsd !== null && evidence.changedLines > 0
  ? Number((evidence.costUsd / evidence.changedLines).toFixed(6)) : null;
evidence.tokensPerChangedLine = evidence.changedLines > 0
  ? Number((total.total / evidence.changedLines).toFixed(2)) : null;
evidence.complete = evidence.costUsd !== null && evidence.changedLines !== null && evidence.qualityExit !== null;

const violations = [];
function enforce(flag, metric, relation, label) {
  if (!values.has(flag)) return;
  const limit = values.get(flag);
  if (metric === null) {
    violations.push({ flag, label, status: "unavailable", actual: null, limit });
  } else if ((relation === "min" && metric < limit) || (relation === "max" && metric > limit)) {
    violations.push({ flag, label, status: "violation", actual: metric, limit });
  }
}
enforce("--min-cache-hit", aggregateMetrics.cacheHitPct, "min", "cacheHitPct");
enforce("--max-cache-write", total.cacheWrite, "max", "cacheWrite");
enforce("--max-input-per-request", aggregateMetrics.accountedInputPeakPerRequest, "max", "accountedInputPeakPerRequest");
enforce("--max-cache-read-per-request", aggregateMetrics.cacheReadPeakPerRequest, "max", "cacheReadPeakPerRequest");

const result = {
  files: files.size,
  sessions,
  ...total,
  requestCountKnown: allRequestCountsKnown,
  metrics: aggregateMetrics,
  evidence,
  violations,
  ...(showSessions ? { sessionRecords } : {}),
};

const printable = (value, suffix = "") => value === null ? "n/a" : `${value}${suffix}`;
if (json) {
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log(`来源文件: ${result.files}  有 usage 会话: ${result.sessions}  请求计数: ${result.requestCountKnown ? result.requests : "部分不可得"}`);
  console.log(`输入: ${result.input}  accounted input: ${result.accountedInput}  缓存读: ${result.cacheRead}  缓存写: ${result.cacheWrite}`);
  console.log(`输出: ${result.output}  推理输出: ${result.reasoning}  总计: ${result.total}`);
  console.log(`缓存命中: ${printable(result.metrics.cacheHitPct, "%")}  缓存写占比: ${printable(result.metrics.cacheWritePct, "%")}  推理占比: ${printable(result.metrics.reasoningPct, "%")}`);
  console.log(`Context floor proxy(平均 cache read/请求): ${printable(result.metrics.contextFloorProxyAvg)}  accounted input 峰值/请求: ${printable(result.metrics.accountedInputPeakPerRequest)}`);
  if (showSessions) {
    console.log("\n会话\tprovider\t请求可信\taccountedInput\tcacheHit%\tcacheWrite\tpeakInput");
    for (const row of sessionRecords) {
      console.log(`${row.source}\t${row.provider}\t${row.requestCountKnown ? "yes" : "no"}\t${row.accountedInput}\t${printable(row.metrics.cacheHitPct)}\t${row.cacheWrite}\t${printable(row.metrics.accountedInputPeakPerRequest)}`);
    }
  }
  console.log(`\n产出证据: ${evidence.complete ? "complete" : "insufficient"}；cost/changed-lines/quality 未显式齐备时不评价代码性价比。`);
  for (const item of violations) {
    console.log(`BUDGET ${item.status.toUpperCase()}: ${item.label} actual=${printable(item.actual)} limit=${item.limit}`);
  }
}

process.exit(violations.length ? 1 : 0);
