#!/usr/bin/env node
/**
 * Core 架构守卫。
 *
 * 检查项：
 * 1. core/src/main/ets 内不存在 import cycle
 * 2. base/ 不反向依赖任何 Kit / 根 CoreInitializer
 * 3. sync/ 不反向依赖根 CoreInitializer
 * 4. 源码中不存在已删除的旧符号 / 旧路径
 * 5. Mock 域名契约（MihoyoDomain.ets）
 * 6. 不存在空源码目录
 *
 * 用法：node scripts/check-architecture.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();
const CORE_ETS = path.join(ROOT, 'core/src/main/ets');
const ENTRY_ETS = path.join(ROOT, 'entry/src/main/ets');

const errors = [];

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) {
    return out;
  }
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, out);
    } else if (entry.name.endsWith('.ets') || entry.name.endsWith('.ts')) {
      out.push(full);
    }
  }
  return out;
}

function relative(file) {
  return path.relative(ROOT, file);
}

function resolveImport(fromFile, spec) {
  if (!spec.startsWith('.')) {
    return null;
  }
  const base = path.resolve(path.dirname(fromFile), spec);
  const candidates = [base, `${base}.ets`, `${base}.ts`, path.join(base, 'Index.ets')];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      return candidate;
    }
  }
  return null;
}

const coreFiles = walk(CORE_ETS);
const fileSet = new Set(coreFiles);
const graph = new Map(coreFiles.map((file) => [file, []]));

for (const file of coreFiles) {
  const source = fs.readFileSync(file, 'utf8');
  const importPattern = /(?:from|export\s+\*\s+from)\s+['"]([^'"]+)['"]/g;
  let match;
  while ((match = importPattern.exec(source)) !== null) {
    const resolved = resolveImport(file, match[1]);
    if (resolved !== null && fileSet.has(resolved) && resolved !== file) {
      const deps = graph.get(file);
      if (!deps.includes(resolved)) {
        deps.push(resolved);
      }
    }
  }
}

// Tarjan SCC
let index = 0;
const indexes = new Map();
const lowLinks = new Map();
const stack = [];
const onStack = new Set();
const cycles = [];

function strongConnect(node) {
  indexes.set(node, index);
  lowLinks.set(node, index);
  index += 1;
  stack.push(node);
  onStack.add(node);

  for (const dep of graph.get(node)) {
    if (!indexes.has(dep)) {
      strongConnect(dep);
      lowLinks.set(node, Math.min(lowLinks.get(node), lowLinks.get(dep)));
    } else if (onStack.has(dep)) {
      lowLinks.set(node, Math.min(lowLinks.get(node), indexes.get(dep)));
    }
  }

  if (lowLinks.get(node) === indexes.get(node)) {
    const component = [];
    let member;
    do {
      member = stack.pop();
      onStack.delete(member);
      component.push(member);
    } while (member !== node);
    if (component.length > 1) {
      cycles.push(component);
    }
  }
}

for (const file of coreFiles) {
  if (!indexes.has(file)) {
    strongConnect(file);
  }
}

for (const cycle of cycles) {
  errors.push(`import cycle: ${cycle.map(relative).join(' -> ')}`);
}

const baseForbidden = /^(GenshinKit|StarRailKit|ZZZKit|MihoyoKit|CoreInitializer)(\/|\.ets$)/;
for (const [file, deps] of graph) {
  const fileRel = path.relative(CORE_ETS, file);
  for (const dep of deps) {
    const depRel = path.relative(CORE_ETS, dep);
    if (fileRel.startsWith('base/') && baseForbidden.test(depRel)) {
      errors.push(`base -> Kit/Core dependency: ${fileRel} -> ${depRel}`);
    }
    if (fileRel.startsWith('sync/') && depRel === 'CoreInitializer.ets') {
      errors.push(`sync -> CoreInitializer dependency: ${fileRel} -> ${depRel}`);
    }
  }
}

const stalePatterns = [
  ['MihoyoApiServiceFactory', /MihoyoApiServiceFactory/g],
  ['baseUrlType', /baseUrlType/g],
  ['CookieManager', /CookieManager/g],
  ['base/cookie path', /base\/cookie/g],
];

const sourceFiles = [...coreFiles, ...walk(ENTRY_ETS)];
for (const file of sourceFiles) {
  const source = fs.readFileSync(file, 'utf8');
  for (const [label, pattern] of stalePatterns) {
    if (pattern.test(source)) {
      errors.push(`stale symbol "${label}" in ${relative(file)}`);
    }
    pattern.lastIndex = 0;
  }
}

const domainFile = path.join(CORE_ETS, 'base/network/MihoyoDomain.ets');
if (!fs.existsSync(domainFile)) {
  errors.push('missing base/network/MihoyoDomain.ets');
} else {
  const source = fs.readFileSync(domainFile, 'utf8');
  if (!source.includes("const MOCK_BASE: string = 'http://127.0.0.1:8787'")) {
    errors.push('MihoyoDomain: MOCK_BASE must be http://127.0.0.1:8787');
  }
  if (!source.includes("'/apihub'")) {
    errors.push('MihoyoDomain: BBS_APIHUB must preserve the /apihub prefix');
  }
}

function collectEmptyDirs(dir, out = []) {
  if (!fs.existsSync(dir)) {
    return out;
  }
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  if (entries.length === 0) {
    out.push(dir);
    return out;
  }
  for (const entry of entries) {
    if (entry.isDirectory()) {
      collectEmptyDirs(path.join(dir, entry.name), out);
    }
  }
  return out;
}

for (const dir of [...collectEmptyDirs(CORE_ETS), ...collectEmptyDirs(ENTRY_ETS)]) {
  errors.push(`empty source directory: ${relative(dir)}`);
}

if (errors.length > 0) {
  console.error('Architecture check failed:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(`Architecture check passed (${coreFiles.length} core source files, 0 cycles).`);
