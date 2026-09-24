<div align="center">

<img src="docs/images/brain-icon.svg" width="150" alt="agent-memory-hub" />

# agent-memory-hub

**Give multiple AI agents one shared, Git-backed memory.**

[English](./README.md) | [简体中文](./README.zh-CN.md)

[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-64748B?style=for-the-badge)](#quick-start)
[![Python](https://img.shields.io/badge/Python-3.8%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Agents](https://img.shields.io/badge/AGENTS-5-7C3AED?style=for-the-badge)](#supported-agents)
[![License](https://img.shields.io/badge/LICENSE-MIT-10B981?style=for-the-badge)](LICENSE)

</div>

---

## 🎯 The problem

Every AI agent tends to keep its own memory, preferences and project context. Switch tools or machines and the context fragments again.

**agent-memory-hub uses a Git repository as a shared memory layer and distributes lightweight pointer files to each agent.**

<p align="center">
  <img src="docs/images/before-after.svg" width="100%" alt="Before and after shared agent memory" />
</p>

---

## ⚡ Quick Start

```bash
git clone https://github.com/Dream22180971/agent-memory-hub.git ~/.shared
cd ~/.shared

bash setup.sh
# Windows PowerShell: .\setup.ps1
```

Then edit `USER.md` with the profile/context you want agents to share.

Daily sync:

```bash
python scripts/sync_memory.py --push
```

---

## 🧩 Architecture

<p align="center">
  <img src="docs/images/architecture.svg" width="100%" alt="agent-memory-hub architecture" />
</p>

| Layer | Files | Responsibility |
|---|---|---|
| **Data** | `USER.md`, `memory/`, `SKILLS.md` | shared profile, memory and skills |
| **Adapters** | `agents/` | per-agent pointer templates |
| **Bootstrap** | `setup.ps1`, `setup.sh` | detect agents and distribute pointers |

The repository stays the source of truth. Agent-specific files remain thin adapters.

---

## 🤖 Supported Agents

| Agent | Status | Pointer location |
|---|---:|---|
| Claude Code | ✅ active | `~/.claude/CLAUDE.md` |
| OpenCode | ✅ active | `~/AGENTS.md` |
| Hermes | ✅ active | `MEMORY.md` + `USER.md` under its config path |
| QClaw | 📦 archived | workspace memory pointer |
| OpenClaw | 📦 archived | workspace memory pointer |

---

## 🔄 Move to another machine

<p align="center">
  <img src="docs/images/cross-device.svg" width="100%" alt="Cross-device memory restore" />
</p>

```bash
git clone git@github.com:<you>/my-memory-hub.git ~/.shared
cd ~/.shared
bash setup.sh
```

The same repository can restore the shared profile, memory index and adapters on a new machine.

---

## 🔐 Privacy

Your memory can contain sensitive personal and project context.

For real use, create your own **private repository** instead of storing personal memory in the public template.

```bash
git remote remove origin
gh repo create my-memory-hub --private
git remote add origin git@github.com:<you>/my-memory-hub.git
git push -u origin main
```

---

## 💡 Why Git instead of a vector database?

This project optimizes for a small, transparent memory layer:

- Markdown stays human-readable.
- Git gives history and cross-device sync.
- Agents can search files directly.
- A vector store can still be added later if scale requires it.

The goal is not to replace memory frameworks. It is to provide a simple source of truth first.

---

## 🗂 Project Structure

```text
agent-memory-hub/
├── USER.md
├── SKILLS.md
├── memory/
├── agents/
│   ├── claude/
│   ├── hermes/
│   ├── opencode/
│   ├── qclaw/
│   └── openclaw/
├── scripts/
│   └── sync_memory.py
├── setup.ps1
├── setup.sh
└── sync.bat
```

---

## 🗺 Roadmap

- [x] Shared Git-backed memory skeleton
- [x] Cross-platform setup scripts
- [x] Multiple agent adapters
- [x] Memory indexing and sync
- [ ] More active agent adapters
- [ ] Better conflict handling
- [ ] Optional scheduled sync helpers
- [ ] Optional semantic-search layer

---

## 🤝 Contributing

Useful PRs include new agent adapters, setup improvements, sync reliability fixes and documentation.

---

## 📄 License

[MIT](LICENSE)

<div align="center">

**One memory source. Many agents. Fewer context resets.**

</div>
