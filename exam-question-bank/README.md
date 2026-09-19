# 考试题库（Exam Question Bank）

期末复习用的题目与答案库。**只存题目与答案**，不按周次/课本顺序组织。

## 科目清单

| 文件名 | 科目 | 中文 |
|---|---|---|
| `Aqeedah.md` | Aqeedah | 信仰学（教义/信条） |
| `Tafsir.md` | Tafsir | 古兰经注 |
| `Hadith.md` | Hadith | 圣训 |
| `Seerah.md` | Seerah | 先知传记（生平） |
| `Fiqh.md` | Fiqh | 教法学 |
| `Tarbiyah-Islamiyah.md` | Tarbiyah Islamiyah | 伊斯兰教育/培养 |
| `Arabic-Language.md` | Arabic Language | 阿拉伯语 |

> 拼写说明：`Tarbiyah Islamiyah` 为标准拼写。

## 目录结构

```
exam-question-bank/
├── README.md             # 本说明
├── init-exam-bank.mjs    # 在另一台电脑建同结构空库的脚本（跨平台，拷过去 node 运行）
├── merge-bank.mjs        # 跨电脑合并脚本（按科目合并、按题目去重，跨平台）
├── Aqeedah.md
├── Tafsir.md
├── Hadith.md
├── Seerah.md
├── Fiqh.md
├── Tarbiyah-Islamiyah.md
└── Arabic-Language.md
```

## 如何加题

把「题目 + 答案」直接发给 Claude，说明这是考试题。Claude 会：

1. 自动识别（拿不准时让你在选项里点选）属于哪一科；
2. 追加到对应 `.md` 文件，`Q` 编号自动递增；
3. 只记「题目 + 正确答案」，干扰选项默认不保留；
4. 迷惑性大的干扰项，在答案后加一句「易混点」提醒；原文照存，不翻译、不改写。

## 题目格式（每科一个文件）

```markdown
## Q001

**题目 (Question):**

（题目内容）

**答案 (Answer):**

（答案内容）
```

- 题与题之间用 `---` 分隔；编号 `Q001`、`Q002`… 自动递增；题目/答案原文照存，可中/英/阿混排。

## 跨电脑合并（两处独立，随时合并）

两处题库各自独立增题，可能两边有重复、有独有。合并时（Windows / macOS 通用，需 Node.js）：

```bash
# 在任一电脑上：把另一台电脑的 exam-question-bank 目录复制过来，作为参数
node merge-bank.mjs "/path/to/另一台电脑的 exam-question-bank"
```

脚本会：逐科（按文件名）合并、按「题目文本」去重、重排 `Q` 编号、覆盖前备份到 `_backup\`（可找回）。

## 在另一台电脑（含 Mac）建同结构题库

**方式 A（最省事，推荐）**：把整个 `exam-question-bank` 目录拷到另一台电脑任意位置（如 Mac 的 `~/Documents/My Projects/`），**直接使用即可**——文件夹里已是完整题库（含本机已存题目），无需运行任何脚本。将来合并时重复题会自动去重。

**方式 B（另一台从空库开始）**：只拷 `init-exam-bank.mjs` 过去，运行（需 Node.js）：

```bash
node init-exam-bank.mjs
```

生成空的 7 科结构（不含本机已存题目）。若目标目录已有含题目的文件，会自动跳过不覆盖。

## 约定

- 只存题目 + 答案，不记录第几周/第几课；
- 只记正确答案，干扰选项默认不保留（迷惑性大时加一句易混点提醒）；
- 题目原文照存，不翻译、不改写。
