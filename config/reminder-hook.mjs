#!/usr/bin/env node
import { readFileSync } from "node:fs";

process.stdout.write(readFileSync(new URL("./token-saver-reminder.md", import.meta.url), "utf8"));
