#!/usr/bin/env node
import { readFileSync } from "node:fs";

let raw = "";
for await (const chunk of process.stdin) raw += chunk;

let event;
try {
  event = JSON.parse(raw);
} catch {
  process.exit(0);
}

if (event.reason !== "end_turn" || event.stopHookActive || !event.lastAssistantMessage) {
  process.exit(0);
}

const drift = /(?:当然[，,!]|好的[，,!]|没问题[，,!]|希望.{0,12}有帮助|如果你愿意|需要我(?:继续|再|帮))|\b(?:certainly|of course|i(?:'|’)d be happy to|hope this helps|let me know if)\b/i;
if (!drift.test(event.lastAssistantMessage)) process.exit(0);

const reminder = readFileSync(new URL("./token-saver-reminder.md", import.meta.url), "utf8").trim();
process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: `[token-saver] 检出客套或续问漂移；删之并重写末答。${reminder}`,
  },
}));
