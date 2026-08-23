# AGENTS.md — OpenCode 全局指令

## 跨 Agent 记忆中枢

本机所有 AI Agent 共享一个记忆层 `{{SHARED}}`：

- 统一用户画像（单一事实来源）：`{{SHARED}}/USER.md`
- 统一记忆索引：`{{SHARED}}/memory/INDEX.md`
- 各 Agent 记忆：`{{SHARED}}/memory/<agent>/`

## 记忆规则

1. 会话开始处理用户请求前，先读 `{{SHARED}}/USER.md` 了解用户画像
2. 需要历史上下文（项目状态、经验教训、平台运营）时查 `{{SHARED}}/memory/INDEX.md`，按索引跳转到具体文件
3. 产生新的长期记忆（用户偏好、经验教训、项目进展）时写入 `{{SHARED}}/memory/opencode/`，命名规范：`feedback_*.md` / `lesson_*.md` / `project_*.md`
4. 用户画像变更直接更新 `{{SHARED}}/USER.md`，不在别处建副本
5. 同步：`python {{SHARED}}/scripts/sync_memory.py`

## 交互偏好

（编辑 `{{SHARED}}/USER.md` 维护，此处不重复）
