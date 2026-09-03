# hermes-skill-sync

> **给 AI agent 的话**：如果你是被人类丢到这个仓库的 agent——直接读 `skills/hermes-skill-sync/SKILL.md`，或执行下面的安装命令把自己装上。装好后你会知道整套 skill 统一源的接入、安装、更新、修改规范。

这是 Hermes Agent **skill 统一源体系的引导仓库**。

- `flowstart/hermes-skills`（私有）= 业务 skill 的**内容真源**
- 本仓库 = **引导 + 运维规范**（怎么接入、怎么装、怎么改、有哪些坑）

## 快速接入

> **权限现状**：本仓库已**公开**（匿名可读/clone）；内容仓库 `flowstart/hermes-skills` 仍是**私有**——装它需要 GitHub 凭据，服务器上推荐下面的设备码自助授权。

```bash
hermes skills tap add flowstart/hermes-skill-sync
hermes skills tap add flowstart/hermes-skills
hermes skills install flowstart/hermes-skill-sync/hermes-skill-sync --yes
# 之后按 skill 里的 Runbook 装 Content skills 并配依赖
```

完整步骤、依赖配置、验证清单、坑清单 → 见 `skills/hermes-skill-sync/SKILL.md`。

## 非 Hermes Agent 怎么用

SKILL.md 是开放约定（Anthropic Agent Skills 同源格式），其他 agent 分三种情况：

| Agent | 用法 |
|---|---|
| **Claude Code / OpenClaw**（认 SKILL.md 格式） | `gh repo clone flowstart/hermes-skill-sync` 后把 `skills/hermes-skill-sync/` 拷进自己的技能目录（Claude Code: `~/.claude/skills/`；OpenClaw: workspace 的 skills/），即被识别加载 |
| **Codex / 其他无技能机制的 agent** | 不用装——直接把 `skills/hermes-skill-sync/SKILL.md` 当 runbook 读，照着执行（命令是普通 shell + git） |
| **任何 agent** | 内容 skill 的 `scripts/` 都是纯 Python/CLI，跨 agent 通用；唯一 agent 特有的是 `hermes skills …` 管理命令，其他 agent 用 `git clone` + 手动拷贝等价替代 |

**权限现状**：本仓库已公开（匿名可 clone/读）；内容仓库 `flowstart/hermes-skills` 仍是私有——装它需要凭据，服务器上推荐 `gh auth login` **设备码自助授权**：agent 在服务器跑登录命令 → 屏幕出 8 位码 → 用户手机打开 https://github.com/login/device 输码确认（约 30 秒，全程不用碰 token 文件）。

## 仓库结构

```
skills/
└── hermes-skill-sync/
    └── SKILL.md     # 引导 skill（tap 只扫 skills/ 一级目录）
```

## 为什么单独建一个仓库

引导 skill 和内容 skill 解耦：把本仓库链接丢给任何一台机器上的 agent，它装上引导 skill 后就掌握了整套体系的使用与维护方法——**仓库即说明书，安装即上手**。本仓库不含任何密钥；内容真源仓库保持私有。
