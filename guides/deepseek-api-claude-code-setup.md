# DeepSeek API + Claude Code 完整搭建指南
## 基于实际部署路径 · 2026年6月18日验证通过

---

## 0. 阅读前须知

本指南适用于 **Windows 10/11** 环境。核心思路：用 **cc-switch** 管理 Claude Code 的 API 配置，将请求定向到 DeepSeek 的 Anthropic 兼容端点。

**不需要科学上网。不需要 Anthropic 账号。** 只需要一个 DeepSeek API Key。

文中所列路径全部为实际部署路径，你可以在你自己的电脑上调整盘符和目录名。

---

## 1. 整体架构速览

```
你在终端输入 claude
        │
        ▼
  Claude Code CLI (v2.1.181)
        │
        │  读取 ~\.claude\settings.json
        │  ├── ANTHROPIC_AUTH_TOKEN = sk-xxx (你的 DeepSeek Key)
        │  └── ANTHROPIC_BASE_URL   = https://api.deepseek.com/anthropic
        │
        ▼
  DeepSeek API (Anthropic 兼容端点)
        │
        │  服务端自动选择底层模型（Chat / Reasoner）
        │
        ▼
  返回结果 → Claude Code 渲染输出
```

**关键认知：** Claude Code 本身不关心你的 API Key 来自哪里。它只读两个环境变量。cc-switch 的作用就是把这两个变量写进 `settings.json`，让你随时切换。

---

## 2. 第一阶段：安装 Node.js + Git

### 2.1 安装 Node.js

1. 下载官方 `.msi` 安装包：https://nodejs.org
2. 安装时**必须修改安装路径**为 `D:\Program Files\NodeJS\`
3. 勾选 "Add to PATH"（安装程序会自动添加）

安装完成后，**关闭所有终端窗口重新打开**，验证：

```powershell
node --version
# 预期输出：v24.16.0（版本号可能更新）

npm --version
# 预期输出：11.13.0
```

### 2.2 安装 Git

1. 下载 Git for Windows：https://git-scm.com
2. 安装路径改为 `D:\Program Files\Git\`
3. 关键步骤：**勾选 "Git from the command line and also from 3rd-party software"**（将 Git 加入 PATH）
4. 其余选项默认即可

验证：

```powershell
git --version
# 预期输出：git version 2.54.0.windows.1
```

---

## 3. 第二阶段：配置 npm（全局安装路径迁移至 D 盘）

默认情况下 npm 全局安装会写入 C 盘。我们把它全部指向 D 盘。

### 3.1 创建目录

```powershell
New-Item -ItemType Directory -Force -Path "D:\Program Files\Claude Code\node_global"
New-Item -ItemType Directory -Force -Path "D:\Program Files\cc-switch"
```

### 3.2 写入 `.npmrc` 配置文件

用记事本打开（或创建）`C:\Users\你的用户名\.npmrc`，写入以下三行：

```
prefix=D:\Program Files\Claude Code\node_global
cache=D:\Program Files\cc-switch
registry=https://registry.npmjs.org
```

**逐行解释：**

| 配置项 | 值 | 含义 |
|--------|-----|------|
| `prefix` | `D:\...\Claude Code\node_global` | `npm install -g` 的安装目标目录 |
| `cache` | `D:\...\cc-switch` | npm 下载缓存（避免每次重新下载） |
| `registry` | `https://registry.npmjs.org` | npm 官方源（国内能直接访问） |

### 3.3 将全局 bin 目录加入系统 PATH

这一步**极其关键**——不加的话终端找不到 `claude` 命令。

1. 按 `Win + R`，输入 `sysdm.cpl`，回车
2. 点击「高级」→「环境变量」
3. 在**上半部分（用户变量）**中找到 `Path`，双击
4. 新增以下条目（按顺序添加）：

```
D:\Program Files\NodeJS
D:\Program Files\Claude Code\node_global
D:\Program Files\Git\cmd
D:\Program Files\Claude Code
D:\Program Files\cc-switch
```

5. 全部点「确定」关闭

验证——新开一个 PowerShell 窗口：

```powershell
npm config get prefix
# 预期输出：D:\Program Files\Claude Code\node_global

npm config get cache
# 预期输出：D:\Program Files\cc-switch
```

---

## 4. 第三阶段：安装 cc-switch（配置管理器）

cc-switch 是一个开源的 Claude Code 配置切换工具，使用 Go 语言编写，通过 npm 分发。

GitHub：https://github.com/HoBeedzc/cc-switch

### 4.1 安装

```powershell
npm install -g @hobeeliu/cc-switch
```

安装完成后，验证：

```powershell
cc-switch --version
# 预期输出：cc-switch version 1.1.1
```

### 4.2 安装后发生了什么

安装脚本（postinstall）做了两件事：

1. **npm 全局安装** → 文件写入 `D:\Program Files\cc-switch\node_modules\@hobeeliu\cc-switch\`
2. **二进制拷贝** → `cc-switch.exe` 复制到 `C:\Users\你的用户名\.claude\cc-switch\cc-switch.exe`

**cc-switch 实际读取和管理的全部文件都在 `~\.claude\` 下：**

```
~\.claude\
├── settings.json              ← Claude Code 读取的当前配置（cc-switch 写入）
├── cc-switch\
│   └── cc-switch.exe          ← Go 二进制（10.7 MB）
└── profiles\                  ← cc-switch 数据目录
    ├── .current               ← 当前激活的配置名
    ├── .history               ← 切换历史
    ├── .update_check          ← 版本检查缓存
    ├── templates\
    │   └── default.json       ← 新配置模板
    ├── default.json           ← 默认配置
    └── deepseek.json          ← 你的 DeepSeek 配置
```

### 4.3 创建一个 DeepSeek 配置

```powershell
cc-switch new deepseek
```

这会基于 `templates/default.json` 创建一个名为 `deepseek` 的新配置。然后编辑它：

```powershell
cc-switch edit deepseek
```

这会用记事本打开 `~\.claude\profiles\deepseek.json`。将其内容改为：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-你的DeepSeek密钥",
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic"
  },
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Glob",
      "Grep",
      "Edit",
      "Write",
      "NotebookEdit",
      "WebSearch",
      "WebFetch",
      "Skill(*)"
    ],
    "deny": []
  }
}
```

**字段解释：**

| 字段 | 值 | 作用 |
|------|-----|------|
| `ANTHROPIC_AUTH_TOKEN` | `sk-xxx`（你的 DeepSeek Key） | Claude Code 会把它当作 Anthropic API Key 发送 |
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` | DeepSeek 的 **Anthropic 兼容端点**——这是 DeepSeek 官方提供的，URL 路径 `/anthropic` 负责将 Anthropic 格式的请求翻译为 DeepSeek 原生格式 |
| `permissions.allow` | 工具白名单 | 控制 Claude Code 可以调用哪些工具 |

### 4.4 激活配置

```powershell
cc-switch use deepseek
```

这一步 cc-switch 做了两件事：
1. 把 `profiles/deepseek.json` 的内容**复制到** `settings.json`
2. 把 `deepseek` 写入 `profiles/.current`

### 4.5 验证配置生效

```powershell
cc-switch current
# 预期输出：Current configuration: deepseek

# 查看 settings.json 确认写入成功
type "$env:USERPROFILE\.claude\settings.json"
```

---

## 5. 第四阶段：安装 Claude Code

### 5.1 安装

```powershell
npm install -g @anthropic-ai/claude-code
```

### 5.2 安装后发生了什么

文件分布：

```
D:\Program Files\Claude Code\
├── claude                  ← 入口脚本（Unix Shell）
├── claude.cmd              ← 入口脚本（Windows CMD）
├── claude.ps1              ← 入口脚本（PowerShell）
├── node_global\
│   └── node_modules\
│       └── @anthropic-ai\
│           └── claude-code\      ← 实际程序（v2.1.181）
│               ├── bin\
│               │   └── claude.exe    ← Windows 可执行文件
│               ├── package.json
│               └── ...
└── node_modules\
```

**调用链：**

```
终端输入 claude
    ↓
D:\Program Files\Claude Code\node_global\claude.ps1
    ↓
D:\Program Files\Claude Code\node_global\node_modules\@anthropic-ai\claude-code\bin\claude.exe
    ↓
读取 ~\.claude\settings.json
    ↓
向 https://api.deepseek.com/anthropic 发送请求
```

### 5.3 验证

```powershell
claude --version
# 预期输出：2.1.181 (Claude Code)
```

---

## 6. 第五阶段：首次启动

确保 cc-switch 已激活 deepseek 配置后：

```powershell
claude
```

**你会看到：**

```
Claude Code v2.1.181
> 
```

此时 Claude Code 已经在跟 DeepSeek 对话了。你可以直接输入问题、让它读取文件、执行命令。

**常见首发命令验证一切正常：**

```
> 你好，当前是什么日期？
> 解释当前目录结构
```

---

## 7. 日常使用场景

### 7.1 在 PowerShell 中直接使用

```powershell
cd 你的项目目录
claude
```

### 7.2 嵌入 VS Code 终端（推荐）

1. 用 VS Code 打开你的项目文件夹
2. 按 `Ctrl + ~` 打开集成终端
3. 确保是 PowerShell
4. 输入 `claude`
5. 在编辑器里看代码，在终端里问 Claude——**不需要切换窗口**

### 7.3 切换 API 配置

```powershell
# 查看所有配置
cc-switch list

# 切换到另一个配置（如果你有多个 API Key）
cc-switch use 另一个配置名

# 回到上一个配置
cc-switch use --previous

# 交互式选择（上下箭头）
cc-switch use
```

### 7.4 备份当前配置

```powershell
cc-switch export --all -o D:\backup-configs.ccx
```

---

## 8. 完整的 PATH 环境变量参考

以下是本机实际生效的用户级 PATH（按顺序排列）：

```
D:\Program Files\NodeJS                        → node.exe
D:\Program Files\Claude Code\node_global       → claude.ps1, cc-switch 入口
D:\Program Files\Git\cmd                       → git.exe
D:\Program Files\Claude Code                   → claude（备用）
D:\Program Files\cc-switch                     → cc-switch（备用）
```

---

## 9. 完整的注册表配置参考

cc-switch 没有注册表项。以下是 Claude Code 生态涉及的所有注册表项（供故障排查）：

| 注册表路径 | 作用 |
|-----------|------|
| `HKLM\Software\GitForWindows` | Git 安装信息 |
| `HKCU\Software\Bandizip` | Bandizip 用户偏好 |
| `HKLM\Software\Bandizip` | Bandizip 安装路径 |
| `HKCU\Software\Tencent\WeCom` | 企业微信禁用自动更新 (`DisableUpdate=1`) |
| `HKCU\Software\Rime` | RIME 输入法用户设置 |
| `HKCU\Software\Classes\SumatraPDF.bat` | .bat 文件关联到 SumatraPDF 启动器 |
| `HKCU\Software\Classes\.pdf` | .pdf 文件关联 |

---

## 10. 备份与恢复（系统崩了也不怕）

详见 `D:\Program Files\Backup\README.md`。

### 备份（崩溃前）

```powershell
powershell -File "D:\Program Files\Backup\backup-all.ps1"
```

自动备份内容：
- `~\.claude\`（包含 cc-switch、profiles、settings.json、历史记录）
- `%APPDATA%\Rime`、`%APPDATA%\Foxmail7`、`%APPDATA%\Code`
- 各应用注册表、安装目录配置文件
- 生成 `manifest.json` 记录每个文件的原路径

### 恢复（重装系统后）

双击 `D:\Program Files\Backup\RESTORE.bat`

1. 读取 `manifest.json`
2. 已安装的应用 → 配置恢复到原位置
3. 未安装的应用 → 跳过（装好后再跑一次即可）

---

## 11. 故障排查

| 症状 | 原因 | 解决方法 |
|------|------|----------|
| `claude : 无法将"claude"项识别为...` | PATH 没配或终端没重启 | 检查 PATH → 重启终端 |
| `npm install -g` 写入 C 盘 | `.npmrc` 未生效 | 确认 `npm config get prefix` 输出 D 盘路径 |
| `cc-switch` 找不到命令 | 安装失败或 PATH 未包含 cc-switch | 重新 `npm install -g @hobeeliu/cc-switch` |
| Claude Code 提示认证失败 | `settings.json` 中 API Key 无效或未激活 | `cc-switch use deepseek` → 检查 key 是否正确 |
| DeepSeek 返回错误 | API Key 余额不足或格式不对 | 登录 DeepSeek 控制台确认 Key 状态 |
| cc-switch 二进制不运行 | 被杀毒软件拦截（Go 编译的 exe） | 添加 Windows Defender 排除项 |

---

## 12. 版本记录

| 组件 | 版本 | 路径 |
|------|------|------|
| Windows | 10 Pro 19044 | — |
| Node.js | v24.16.0 | `D:\Program Files\NodeJS\` |
| npm | 11.13.0 | 随 Node.js |
| Git | 2.54.0 | `D:\Program Files\Git\` |
| cc-switch | 1.1.1 | npm: `@hobeeliu/cc-switch` |
| Claude Code | 2.1.181 | npm: `@anthropic-ai/claude-code` |

---

> **这份指南基于 2026-06-18 实际部署环境穷尽探索后写出。**
> 备份脚本 `backup-all.ps1` 和恢复脚本 `RESTORE.bat` 在 `D:\Program Files\Backup\`。
> 每安装一个新应用后跑一次 `backup-all.ps1`，系统崩溃后双点 `RESTORE.bat`，全部配置秒回。
