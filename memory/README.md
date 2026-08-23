# memory/

Agent 记忆数据积累在这里。同步脚本会为每个检测到的 Agent 创建子目录：

- `claude/` — 从 Claude Code 各项目收集的记忆
- `hermes/` — Hermes 根文件 + 会话导出
- `opencode/` — OpenCode 直接写入的长期记忆

`INDEX.md` 由 `scripts/sync_memory.py` 自动生成，勿手动编辑。

**注意**：这个目录包含你的私有记忆，请只推送到你自己的私有仓库。
