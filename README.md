# hermes-skill-sync

> **给 AI agent 的话**：如果你是被人类丢到这个仓库的 agent——直接读 `skills/hermes-skill-sync/SKILL.md`，或执行下面的安装命令把自己装上。装好后你会知道整套 skill 统一源的接入、安装、更新、修改规范。

这是 Hermes Agent **skill 统一源体系的引导仓库**。

- `flowstart/hermes-skills`（私有）= 业务 skill 的**内容真源**
- 本仓库 = **引导 + 运维规范**（怎么接入、怎么装、怎么改、有哪些坑）

## 快速接入（本机已配 gh 凭据时）

```bash
hermes skills tap add flowstart/hermes-skill-sync
hermes skills tap add flowstart/hermes-skills
hermes skills install flowstart/hermes-skill-sync/hermes-skill-sync --yes
# 之后按 skill 里的 Runbook 装 Content skills 并配依赖
```

完整步骤、依赖配置、验证清单、坑清单 → 见 `skills/hermes-skill-sync/SKILL.md`。

## 仓库结构

```
skills/
└── hermes-skill-sync/
    └── SKILL.md     # 引导 skill（tap 只扫 skills/ 一级目录）
```

## 为什么单独建一个仓库

引导 skill 和内容 skill 解耦：把本仓库链接丢给任何一台机器上的 agent，它装上引导 skill 后就掌握了整套体系的使用与维护方法——**仓库即说明书，安装即上手**。本仓库不含任何密钥；内容真源仓库保持私有。
