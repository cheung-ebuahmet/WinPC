# My Projects — 管理工具箱

Windows 系统配置、应用管理、安全修复的脚本集合。所有脚本均为独立可运行文件。

---

## 📁 目录结构

```
My Projects/
├── README.md                   ← 你正在看的文件
├── scripts/                    ← 可执行脚本（按功能分类）
│   ├── system/                 ← 系统优化
│   ├── startmenu/              ← 开始菜单
│   ├── security/               ← 安全中心修复
│   ├── apps/                   ← 应用安装与配置
│   ├── cjk/                    ← 编码/终端/输入法
│   └── upgrade/                ← Windows 升级诊断（仅参考）
├── guides/                     ← 参考文档
├── config/                     ← 配置文件
└── memory/                     ← Claude Code 自动记忆（.claude 内部）
```

> ⚠️ **重要：** 这个目录只存放管理系统和软件的脚本/指南。
> **工程文件**在 `D:\Documents\Wilson\`（合同、图纸、项目文档）——两者完全分开，互不影响。

---

## 🟢 scripts/system/ — 系统优化

| 脚本 | 功能 | 何时运行 |
|------|------|---------|
| `startmenu-boost-performance.ps1` | 开始菜单加速 + CPU 优先级提升 + 动画关闭 | 新装系统后 |
| `remove-bloatware.ps1` | 卸载 Windows 预装垃圾应用 | 新装系统后 |
| `block-office-auto-updates.ps1` | 阻止 Office 365 自动更新 | Office 安装后 |
| `create-restore-point.ps1` | 创建系统还原点 | 重大变更前 |

```
用法：右键脚本 → 使用 PowerShell 运行（管理员）
```

---

## 🔵 scripts/startmenu/ — 开始菜单

| 脚本 | 功能 |
|------|------|
| `startmenu-cleanup-and-organize.ps1` | 清理冗余快捷方式 + 整理分组 |
| `startmenu-add-shortcuts.ps1` | 添加自定义应用快捷方式到菜单 |
| `hide-broken-entry.ps1` | 隐藏 `ms-resource:DisplayName` 破损条目（安全中心修复） |

---

## 🔴 scripts/security/ — Windows 安全中心

| 脚本 | 功能 | 状态 |
|------|------|------|
| `fix-sec-health.ps1` | 解除策略锁 + 恢复安全中心服务 | ✅ 已执行 |
| `fix-pri.cmd` | 替换损坏的 PRI 资源文件 | ⚠️ 备用 |
| `deploy-sechealth.cmd` | SYSTEM 权限部署 PRI 替换 | ⚠️ 备用 |
| `replace-pri.ps1` | 从 KB 提取替换 PRI 文件 | ⚠️ 已尝试 |
| `install-KB5094127.ps1` | 安装 KB5094127 更新修复安全中心 | ⚠️ UUP 格式不支持 |

> 破损条目已通过 AppListEntry="none" 隐藏，安全中心功能完整可搜索使用。

---

## 🟡 scripts/apps/ — 应用管理

| 脚本 | 功能 |
|------|------|
| `install-wecom.ps1` | 企业微信静默安装 + 禁用自动更新 |
| `relocate-wecom-data.ps1` | 企业微信数据路径迁移到 `D:\Documents\WeCom\` |
| `install-rime-weasel.ps1` | 小狼毫输入法安装 + 初始配置 |
| `remove-nvidia-admin.ps1` | 彻底卸载 NVIDIA 全部残留 |

---

## 🟣 scripts/cjk/ — 编码与终端

| 脚本 | 功能 |
|------|------|
| `fix-cjk-console-font.ps1` | 修复控制台 CJK 字体渲染 |
| `fix-cjk-terminal.ps1` | 修复所有终端环境（PS/CMD/Bash）的中文显示 |

---

## ⚪ scripts/upgrade/ — 升级诊断（历史参考）

| 脚本 | 功能 |
|------|------|
| `diagnose-post-upgrade.ps1` | 21H2→22H2 升级后全面配置变更审计 |
| `fix-post-upgrade.ps1` | 修复升级后发现的问题 |

> 这些是 2026-06-20 针对升级的诊断文件。日常不需要运行。

---

## 📖 guides/ — 参考文档

| 文件 | 内容 |
|------|------|
| `deepseek-api-claude-code-setup.md` | DeepSeek API + Claude Code 完整搭建指南 |
| `toolbox-index.md` | 工具箱功能索引 |

---

## ⚙️ config/ — 配置文件

| 文件 | 用途 |
|------|------|
| `.env` | 环境变量 |
| `mcp.json` | MCP 服务器配置（MarkItDown 等） |

---

## 🔄 备份

所有脚本和指南已纳入 `D:\Program Files\Backup\backup-all.ps1` 自动备份（Phase 5）。

恢复时运行 `D:\Program Files\Backup\RESTORE.bat` 即可完整还原 `scripts/` + `guides/` + `config/`。

---

## 🛠️ 相关工具链

| 工具集 | 位置 | 用途 |
|------|------|------|
| **PDF 工具箱** | `D:\Applications\ocr-tools\` | OCR、PDF→MD、可搜索 PDF |
| **系统备份** | `D:\Program Files\Backup\` | 应用配置 + 注册表 + 开始菜单一键备份恢复 |
| **应用软件** | `D:\Program Files\<App>\` | 所有应用安装目录 |
| **用户数据** | `D:\Documents\` | 聊天记录、邮件、工程文件 |
