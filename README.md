# hermes-skill-sync

> **给 AI agent 的话**：如果你是被人类丢到这个仓库的 agent——读 `skills/hermes-skill-sync/SKILL.md`，按你的 agent 类型（Hermes / Claude Code / Codex / OpenClaw / 其他）挑对应的 Runbook 执行。装好后你会知道整套 skill 统一源的接入、安装、更新、修改、入源规范。

这是 **skill 统一源体系的引导仓库**，面向任何 agent。

- `flowstart/hermes-skills`（私有）= 业务 skill 的**内容真源**
- 本仓库（公开）= **引导 skill + 一键接入脚本 + 运维规范**

## 快速接入

**Hermes Agent**

```bash
hermes skills tap add flowstart/hermes-skill-sync
hermes skills tap add flowstart/hermes-skills
hermes skills install flowstart/hermes-skill-sync/hermes-skill-sync --yes
# 之后按 SKILL.md 的 Runbook A 装内容 skill
```

**Claude Code / Codex / OpenClaw**（一条命令，软链到该 agent 的技能目录，更新只需重跑）

```bash
git clone https://github.com/flowstart/hermes-skill-sync.git ~/Desktop/GitHub/hermes-skill-sync
bash ~/Desktop/GitHub/hermes-skill-sync/skills/hermes-skill-sync/scripts/sync.sh --target claude --all   # 或 codex / openclaw
```

**没有技能机制的 agent**：clone 两个仓库，把 `skills/<名>/SKILL.md` 当 runbook 读。

> 内容仓私有，clone 它需要 GitHub 凭据。服务器上首选 `gh auth login` 设备码：屏幕出 8 位码 → 用户手机打开 https://github.com/login/device 输码，约 30 秒，不碰 token 文件。本仓库公开，不需要凭据。

各 agent 的技能目录、参数说明、更新/修改流程、新 skill 入源检查、坑清单、验证清单 → 全在 `skills/hermes-skill-sync/SKILL.md`。

## 仓库结构

```
skills/
└── hermes-skill-sync/
    ├── SKILL.md            # 引导 skill（tap 只扫 skills/ 一级目录）
    └── scripts/
        └── sync.sh         # 非 Hermes agent 的一键接入/更新/检查脚本
```

## 为什么单独建一个仓库

引导和内容解耦：把本仓库链接丢给任何一台机器上的任何 agent，它装上引导 skill 就掌握了整套体系的使用与维护方法——**仓库即说明书，安装即上手**。本仓库不含任何密钥；内容真源保持私有。
