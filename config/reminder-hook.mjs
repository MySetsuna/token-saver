#!/usr/bin/env node
import { readFileSync } from "node:fs";

const reminder = readFileSync(new URL("./token-saver-reminder.md", import.meta.url), "utf8").trim();

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: reminder,
  },
}));
