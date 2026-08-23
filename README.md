# agent-memory-hub

**一个 Git 仓库，让你的所有 AI Agent 共用一个大脑。**

换一台电脑，`git clone` + 跑一个脚本，所有 Agent 立刻恢复对你的全部记忆——你是谁、你在做什么项目、你踩过什么坑、你喜欢什么风格。

```
你 ←──→ Claude Code / OpenCode / Hermes / QClaw / OpenClaw ...
              ↑                    ↑
              └──── 同一个大脑 ──────┘
                 ~/.shared/（一个 Git 仓库）
                 ├── USER.md          你是谁（单一事实来源）
                 ├── memory/          所有 Agent 的记忆归档
                 ├── agents/          各 Agent 的接入指针
                 └── scripts/         同步脚本
```

## 为什么需要它

每个 AI Agent 默认各自失忆：

- Claude 记住的偏好，OpenCode 不知道；Hermes 聊过的项目，Claude 一无所知
- 每换个 Agent / 换台设备，重新自我介绍一遍
- 散落在各 Agent 目录里的记忆文件，没有备份，换机即丢

**agent-memory-hub 的答案：不造新轮子，用一个 Git 仓库当共享大脑，每个 Agent 放一个指针文件指向它。**

## 快速开始

```bash
# 1. clone 到任意固定位置（建议 ~/.shared）
git clone https://github.com/<you>/agent-memory-hub ~/.shared

# 2. 运行安装脚本（自动检测你装了哪些 Agent，只为它们接入）
cd ~/.shared
bash setup.sh          # Linux / macOS
.\setup.ps1            # Windows PowerShell

# 3. 编辑 USER.md，填上你是谁
```

装好之后什么都不用做。Agent 们会按指针文件里的指令，在会话开始时读你的画像、按需查记忆索引、把新的长期记忆写回中枢。

日常同步（把各 Agent 新产生的记忆归档 + 提交）：

```bash
python scripts/sync_memory.py --push   # 或双击 sync.bat（Windows）
```

## ⚠️ 先做这一步：转成你自己的私有仓库

本仓库只是**骨架**。你的记忆（画像、项目、偏好）是隐私数据，**绝不能推到公开仓库**。

```bash
# 删掉指向本仓库的 remote，换成你自己的私有仓库
git remote remove origin
gh repo create my-memory-hub --private        # 或在 GitHub 网页上建
git remote add origin git@github.com:<你>/my-memory-hub.git
git push -u origin main
```

## 工作原理

三层结构，加起来不到 500 行代码：

| 层 | 目录 | 职责 |
|----|------|------|
| 数据层 | `USER.md` `memory/` | 记忆本体：画像 + 各 Agent 记忆归档，`INDEX.md` 自动生成 |
| 引导层 | `setup.ps1` `setup.sh` | 新设备初始化：检测 OS、检测装了哪些 Agent、分发指针文件 |
| 适配层 | `agents/` | 每个 Agent 一份指针文件模板，告诉它去哪读、往哪写 |

**指针文件 = 接入的全部代价。** `setup` 把 `agents/<name>/` 下的模板复制到各 Agent 的约定位置（如 OpenCode 的 `~/AGENTS.md`、Claude 的 `~/.claude/CLAUDE.md`、Hermes 的 `~/.hermes/MEMORY.md`），其中的 `{{SHARED}}` 占位符替换为中枢实际路径。

## 支持的 Agent

| Agent | 检测方式 | 指针位置 |
|-------|----------|----------|
| OpenCode | `opencode` 命令或 `~/.config/opencode` | `~/AGENTS.md` |
| Claude Code | `~/.claude` | `~/.claude/CLAUDE.md` |
| Hermes | `~/.hermes` / `~/.config/hermes` / `%LOCALAPPDATA%\hermes` | `<hermes-dir>/MEMORY.md` + `USER.md` |
| QClaw | `~/.qclaw/workspace` | `workspace/MEMORY.md` |
| OpenClaw | `~/.openclaw/workspace` | `workspace/MEMORY.md` |

新增一个 Agent = 在 `agents/` 加一个模板目录 + `setup` 加三行检测。欢迎 PR。

## 换设备

```bash
git clone git@github.com:<你>/my-memory-hub.git ~/.shared
cd ~/.shared && bash setup.sh     # 或 .\setup.ps1
```

10 秒后，大脑完整复活。想要**全新大脑**（不带历史记忆）？`bash setup.sh --fresh` 只保留骨架。

## 设计决策（FAQ）

**为什么不用 mem0 / Letta / basic-memory？**
它们解决的是"语义检索"（向量数据库、知识图谱），在几百个 md 文件的规模下，`INDEX.md` + Agent 自己 grep 完全够用。等到不够用的那天，这类服务可以无痛叠加——md 文件仍是真相源。

**为什么指针文件用复制，不用 symlink？**
Windows 上建文件级 symlink 需要开发者模式；更致命的是 Agent 卸载/重装后 symlink 变死链且难以察觉。复制 + `-Force` 重新分发，没有这些问题。

**为什么 git commit 写在 sync 脚本里，而不是 git hooks？**
git hooks 只在 git 操作时触发，监听不到 Agent 直接写文件。同步脚本末尾 commit（`--no-git` 可跳过）+ 可选的定时任务，才是可靠路径。

**自动同步？**
Windows 任务计划程序每天跑一次 `sync.bat`；Linux/macOS 用 cron。见 `sync_memory.py --push`。

## License

[MIT](LICENSE)
