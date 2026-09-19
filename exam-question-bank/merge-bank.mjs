#!/usr/bin/env node
// merge-bank.mjs — 跨电脑合并题库（跨平台：Windows + macOS，需 Node.js）
//
// 用法:
//   node merge-bank.mjs <另一台电脑的 exam-question-bank 目录> [目标题库目录]
//   目标目录默认 = 本脚本所在目录（即本机题库目录）。
//
// 行为:
//   - 逐科目 .md 合并（跳过 README / SETUP 等说明文件）
//   - 按「题目文本」（规范化后）去重：两边相同的题只保留一份
//   - 合并后 Q 编号自动重排 Q001、Q002…
//   - 被覆盖的目标文件先备份到 _backup 子目录（时间戳后缀），可找回

import { readFileSync, writeFileSync, mkdirSync, copyFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('用法: node merge-bank.mjs <另一台电脑的 exam-question-bank 目录> [目标题库目录]');
  process.exit(1);
}
const incoming = resolve(args[0]);
const target = args[1] ? resolve(args[1]) : __dirname;

if (!existsSync(incoming)) {
  console.error('找不到待合并目录: ' + incoming);
  process.exit(1);
}

// ---- 辅助函数 ----

// 把一个科目文件拆成「前导说明」+「题目块数组」
function splitSubject(content) {
  const lines = content.split(/\r?\n/);
  const preamble = [];
  const blocks = [];
  let cur = null;
  let inPreamble = true;
  for (const line of lines) {
    if (/^##\s*Q\d+/.test(line)) {
      if (cur !== null) blocks.push(finalize(cur));
      cur = [line];
      inPreamble = false;
    } else if (inPreamble) {
      preamble.push(line);
    } else if (cur !== null) {
      cur.push(line);
    }
  }
  if (cur !== null) blocks.push(finalize(cur));
  return { preamble: preamble.join('\n').replace(/(\s*---\s*)+$/, '').trimEnd(), blocks };
}

// 清理块末尾残留的分隔线（--- 与空白）
function finalize(list) {
  return list.join('\n').replace(/(\s*---\s*)+$/, '').trim();
}

// 提取「题目」文本作为去重键
function questionKey(block) {
  const m = block.match(/\*\*题目[\s\S]*?\*\*\s*([\s\S]*?)\s*\*\*答案/);
  const s = m ? m[1] : block;
  return s.replace(/\s+/g, ' ').trim().toLowerCase();
}

// 重写块首行的 Q 编号
function setNumber(block, num) {
  const lines = block.split(/\r?\n/);
  lines[0] = '## Q' + String(num).padStart(3, '0');
  return lines.join('\n');
}

// ---- 主流程 ----
const backupDir = join(target, '_backup');
mkdirSync(backupDir, { recursive: true });

const incomingMd = readdirSync(incoming).filter((n) => {
  return n.endsWith('.md') && !/^(README|SETUP)/.test(n);
});
if (incomingMd.length === 0) {
  console.error('待合并目录里没有科目 .md 文件: ' + incoming);
  process.exit(1);
}

for (const name of incomingMd) {
  const targetFile = join(target, name);
  const seen = new Set();
  const merged = [];
  let preamble = null;

  // 先读目标已有题目（若有）
  if (existsSync(targetFile)) {
    const t = splitSubject(readFileSync(targetFile, 'utf8'));
    preamble = t.preamble;
    for (const b of t.blocks) {
      const k = questionKey(b);
      if (!seen.has(k)) { seen.add(k); merged.push(b); }
    }
    // 备份原文件
    const stamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14);
    copyFileSync(targetFile, join(backupDir, basename(name, '.md') + '.' + stamp + '.bak.md'));
  }

  // 再并入待合并题目
  const inc = splitSubject(readFileSync(join(incoming, name), 'utf8'));
  if (preamble === null) preamble = inc.preamble;
  for (const b of inc.blocks) {
    const k = questionKey(b);
    if (!seen.has(k)) { seen.add(k); merged.push(b); }
  }

  // 重新编号并组装
  const parts = [preamble];
  for (let i = 0; i < merged.length; i++) {
    parts.push('', '---', '', setNumber(merged[i], i + 1));
  }
  writeFileSync(targetFile, parts.join('\n') + '\n', 'utf8');

  console.log(name + ': 合并后 ' + merged.length + ' 题');
}
