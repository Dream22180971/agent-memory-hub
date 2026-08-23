# Hermes Memory

> Hermes Agent 已接入跨 Agent 记忆中枢。

## 共享记忆层（先读这里）

- 统一用户画像：`{{SHARED}}/USER.md`
- 统一记忆索引：`{{SHARED}}/memory/INDEX.md`

## 使用规则

1. 会话开始时先读 `{{SHARED}}/USER.md` 和 `{{SHARED}}/memory/INDEX.md`
2. 新的长期记忆写入 `{{SHARED}}/memory/hermes/`（feedback_*.md / lesson_*.md / project_*.md）
3. 用户画像变更直接更新 `{{SHARED}}/USER.md`（单一事实来源，勿在本机建副本）

## Hermes 本地记忆

（随会话积累；同步脚本会自动把本文件和 state.db 会话归档到共享层）
