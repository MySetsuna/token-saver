#!/usr/bin/env node
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("用法: node bin/run-bash.mjs <script> [args...]");
  process.exit(2);
}

function command(name) {
  const r = spawnSync(process.platform === "win32" ? "where.exe" : "command", process.platform === "win32" ? [name] : ["-v", name], {
    encoding: "utf8",
    shell: process.platform !== "win32",
  });
  return r.status === 0 ? r.stdout.split(/\r?\n/).filter(Boolean) : [];
}

function findBash() {
  if (process.env.GIT_BASH && existsSync(process.env.GIT_BASH)) return process.env.GIT_BASH;
  if (process.platform !== "win32") return "bash";

  const candidates = [
    `${process.env.ProgramFiles || "C:\\Program Files"}\\Git\\bin\\bash.exe`,
    `${process.env["ProgramFiles(x86)"] || "C:\\Program Files (x86)"}\\Git\\bin\\bash.exe`,
    `${process.env.LocalAppData || ""}\\Programs\\Git\\bin\\bash.exe`,
    ...command("bash.exe").filter((p) => !/\\Windows\\System32\\bash\.exe$/i.test(p)),
  ];
  const bash = candidates.find((p) => p && existsSync(p));
  if (!bash) {
    console.error("未找到 Git Bash。请安装 Git for Windows，或设置 GIT_BASH 指向 bash.exe。");
    process.exit(127);
  }
  return bash;
}

function toMsysPath(p) {
  const full = resolve(p);
  const m = /^([A-Za-z]):\\(.*)$/.exec(full);
  if (!m) return full.replaceAll("\\", "/");
  return `/${m[1].toLowerCase()}/${m[2].replaceAll("\\", "/")}`;
}

function shQuote(s) {
  return `'${s.replaceAll("'", "'\\''")}'`;
}

const [script, ...rest] = args;
let r;
if (process.platform === "win32") {
  const cmd = [
    `export PATH=${shQuote(toMsysPath(dirname(process.execPath)))}:$PATH;`,
    shQuote(toMsysPath(script)),
    ...rest.map(shQuote),
  ].join(" ");
  r = spawnSync(findBash(), ["-lc", cmd], { stdio: "inherit" });
} else {
  r = spawnSync(findBash(), [resolve(script), ...rest], { stdio: "inherit" });
}
process.exit(r.status ?? 1);
