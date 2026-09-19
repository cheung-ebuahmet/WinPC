#!/usr/bin/env node
// init-exam-bank.mjs — 在一台电脑上创建与另一台一致的「期末考试题库」空结构（跨平台：Windows + macOS）
//
// 用法:
//   node init-exam-bank.mjs [目标目录]
//   目标目录默认 = 当前目录；若已在 exam-question-bank 目录内，则在其上一级创建（避免嵌套）。
//
// 说明:
//   运行后生成 exam-question-bank\ 目录，含 7 个科目空文件 + README.md。
//   若本脚本同目录下还有 merge-bank.mjs / README.md，会一并复制进去。

import { mkdirSync, writeFileSync, copyFileSync, existsSync, readFileSync } from 'node:fs';
import { join, resolve, basename, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

let base = process.argv[2] ? resolve(process.argv[2]) : process.cwd();
if (basename(base) === 'exam-question-bank') base = dirname(base);
const bankDir = join(base, 'exam-question-bank');
mkdirSync(bankDir, { recursive: true });

// 科目清单（顺序固定，文件名 kebab-case，两处必须一致）
const subjects = [
  ['Aqeedah.md',            'Aqeedah',            '信仰学（教义/信条）'],
  ['Tafsir.md',             'Tafsir',             '古兰经注'],
  ['Hadith.md',             'Hadith',             '圣训'],
  ['Seerah.md',             'Seerah',             '先知传记（生平）'],
  ['Fiqh.md',               'Fiqh',               '教法学'],
  ['Tarbiyah-Islamiyah.md', 'Tarbiyah Islamiyah', '伊斯兰教育/培养'],
  ['Arabic-Language.md',    'Arabic Language',    '阿拉伯语'],
];

for (const [file, name, zh] of subjects) {
  const p = join(bankDir, file);
  // 已含题目的文件跳过，避免重复运行覆盖已存数据
  if (existsSync(p) && /^##\s*Q\d+/m.test(readFileSync(p, 'utf8'))) {
    console.log('跳过（已含题目，不覆盖）：' + file);
    continue;
  }
  const content = '# ' + name + '\n\n' +
    '> 存放 ' + name + '（' + zh + '）的题目与答案。\n' +
    '> 追加格式：## Q### 标题 + **题目 (Question):** + **答案 (Answer):**，题与题之间用 --- 分隔，编号由 Claude 自动递增。\n';
  writeFileSync(p, content, 'utf8');
}

// 精简版 README（无 Markdown 反引号，避免脚本内嵌转义问题）
const fallbackReadme = [
  '# 考试题库（Exam Question Bank）',
  '',
  '期末复习用的题目与答案库。只存题目与答案，不按周次/课本顺序组织。',
  '',
  '科目：Aqeedah / Tafsir / Hadith / Seerah / Fiqh / Tarbiyah Islamiyah / Arabic Language',
  '',
  '把「题目 + 答案」直接发给 Claude，Claude 自动识别科目并追加到对应 .md 文件。',
  '只记正确答案，干扰选项默认不保留；迷惑性大时加一句「易混点」提醒。',
  '',
  '跨电脑合并（需 Node.js）：node merge-bank.mjs <另一台电脑的题库目录>',
].join('\n') + '\n';
const readmePath = join(bankDir, 'README.md');
if (!existsSync(readmePath)) {
  writeFileSync(readmePath, fallbackReadme, 'utf8');
}

// 把同目录的 merge-bank.mjs / README.md 一并带进题库（若存在，则用它们覆盖精简版）
for (const f of ['merge-bank.mjs', 'README.md']) {
  const src = join(__dirname, f);
  const dst = join(bankDir, f);
  if (existsSync(src) && src !== dst) {
    copyFileSync(src, dst);
  }
}

console.log('');
console.log('题库结构已创建：' + bankDir);
console.log('  科目文件 7 个 + README.md' + (existsSync(join(bankDir, 'merge-bank.mjs')) ? ' + merge-bank.mjs' : ''));
console.log('  以后在这台电脑上贴题，Claude 会自动识别科目并追加到对应 .md。');
