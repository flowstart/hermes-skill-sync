---
name: hermes-skill-sync
description: 自建 skill 统一源（flowstart/hermes-skills）的接入与运维引导，面向任何 agent——Hermes、Claude Code、Codex、OpenClaw，或没有技能机制的 agent。装了它就知道：怎么把内容真源接到当前 agent（Hermes 用 tap，其他 agent 用 scripts/sync.sh 一条命令）、怎么更新、怎么改、新 skill 怎么入源、实测坑。触发词：接入skill源、skill同步、安装skill、更新skill、hermes-skills、统一真源、把 xx skill 入源、这台机器怎么装 skill。
---

# Skill 统一源 · 接入与运维

一句话：所有机器、所有 agent 的业务 skill 都从同一个 git 仓库来；改只在工作副本改，各端只拉不改。本文档是接入这套体系的唯一入口，按你的 agent 类型挑对应的 Runbook 执行即可。

## 一、体系

| 仓库 | 角色 | 可见性 | 工作副本固定路径 |
|---|---|---|---|
| `flowstart/hermes-skill-sync` | 引导 skill（本文档）+ `scripts/sync.sh` | 公开 | `~/Desktop/GitHub/hermes-skill-sync` |
| `flowstart/hermes-skills` | 内容真源：`skills/<名>/SKILL.md` | 私有 | `~/Desktop/GitHub/hermes-skills` |

**唯一规则**：skill 只在内容仓的工作副本里改 → commit → push → 各端更新。安装到各 agent 的拷贝/软链一律不手改，改了会被下次更新覆盖（Hermes）或直接污染源（软链）。

工作副本路径所有机器统一，脚本和文档都默认它；要换用环境变量 `HERMES_SKILLS_DIR` / `HERMES_SKILL_SYNC_DIR` 覆盖。路径不存在时 `sync.sh` 会自动 clone。

## 二、你是哪种 agent → 走哪条 Runbook

| Agent | 技能目录 | Runbook |
|---|---|---|
| Hermes Agent | `~/.hermes/skills/`（profile 各自独立） | A：`hermes skills tap` |
| Claude Code | `~/.claude/skills/` | B：`sync.sh --target claude` |
| Codex CLI | `~/.codex/skills/`（项目级可用 `.agents/skills/`） | B：`sync.sh --target codex` |
| OpenClaw | `<workspace>/skills/`（workspace 读 `~/.openclaw/openclaw.json`） | B：`sync.sh --target openclaw` |
| 没有技能机制的 agent | 无 | C：把 SKILL.md 当 runbook 读 |

Claude Code / Codex 都能识别软链目录（macOS 实测），所以 B 默认用软链：工作副本 `git pull` 之后各端立即生效，不存在"拷贝分叉"。

## 三、凭据（内容仓私有，只有这一步需要人）

先看有没有：`gh auth status`。有就跳过。没有：

```bash
gh auth login    # GitHub.com → HTTPS → "Login with a web browser"
```

屏幕出 8 位码 → 让用户用手机打开 https://github.com/login/device 输码确认，约 30 秒，全程不碰 token 文件。这是服务器上的首选方式；agent 自己做不了浏览器确认那一步，要明确告诉用户"请输码"。

替代：fine-grained PAT，只勾这两个仓 + Contents:Read。Hermes 放 `~/.hermes/.env` 的 `GH_TOKEN=`；其他 agent 走 `gh auth login --with-token`。国内服务器先确认 `curl -I https://api.github.com` 通。

引导仓是公开的，不需要凭据。

## Runbook A · Hermes

```bash
hermes --version                                   # 前提
hermes skills tap add flowstart/hermes-skill-sync
hermes skills tap add flowstart/hermes-skills
hermes skills tap list                             # 应有两条
hermes skills search order-quote                   # 验证可发现
hermes skills install flowstart/hermes-skill-sync/hermes-skill-sync --yes
hermes skills install flowstart/hermes-skills/<skill名> --yes
hermes -p <profile名> skills install flowstart/hermes-skills/<skill名> --yes   # profile 是独立拷贝，要用就单独装
```

日常：`hermes skills check && hermes skills update`（拉齐）、`hermes skills audit`（审计）、`hermes curator status`（生命周期，永不删除）。

## Runbook B · Claude Code / Codex / OpenClaw

**第一次（这台机器还没有工作副本）**：

```bash
git clone https://github.com/flowstart/hermes-skill-sync.git ~/Desktop/GitHub/hermes-skill-sync
bash ~/Desktop/GitHub/hermes-skill-sync/skills/hermes-skill-sync/scripts/sync.sh --target claude --all
```

把 `claude` 换成 `codex` 或 `openclaw` 即可。脚本会：clone/pull 两个工作副本 → 把引导 skill + 选中的 skill 软链到该 agent 的技能目录 → 打印生效方式。目标位置已有同名真实目录时会先备份到 `~/.hermes-skill-sync/backups/`（不放技能目录里，避免重名冲突）再换成软链。

常用参数：

```bash
sync.sh --target codex --skill order-quote          # 只装一个
sync.sh --target claude --check                     # 只看状态：linked / copied / copied-stale / missing / foreign-link
sync.sh --target openclaw --all --mode copy         # 软链不方便的环境用拷贝（之后更新要重跑）
sync.sh --target claude --all --dry-run             # 先看会做什么
sync.sh --target openclaw --workspace /path/to/ws   # OpenClaw workspace 不在默认位置
```

**生效**：Claude Code / Codex 开新会话即可，Codex 也可 `$<skill名>` 显式调用；OpenClaw 重载 workspace。

**更新**：重跑同一条命令。软链模式下其实 `git -C ~/Desktop/GitHub/hermes-skills pull` 就生效，重跑是为了补上新入源的 skill。

**Codex 项目级用法**：某个仓库要带着 skill 走，把 `skills/<名>` 软链进该仓库的 `.agents/skills/`，或在其 `AGENTS.md` 加一行指向工作副本的 SKILL.md。

## Runbook C · 没有技能机制的 agent

```bash
git clone https://github.com/flowstart/hermes-skill-sync.git ~/Desktop/GitHub/hermes-skill-sync
gh repo clone flowstart/hermes-skills ~/Desktop/GitHub/hermes-skills     # 需凭据，见第三节
```

然后把 `~/Desktop/GitHub/hermes-skills/skills/<名>/SKILL.md` 当 runbook 读，照着执行。内容 skill 的 `scripts/` 都是纯 Python / shell，不依赖任何 agent；`references/`、`assets/` 是相对路径引用，clone 下来就能用。

## 四、修改与新增 skill

```bash
cd ~/Desktop/GitHub/hermes-skills/skills/<skill名>/
# 改 SKILL.md / scripts/ / references/ …
git add -A && git commit -m "feat(<skill名>): xxx" && git push
# 各端：Hermes → hermes skills check && hermes skills update；其他 → 软链已生效 / 重跑 sync.sh
```

**新 skill 入源检查（推之前逐条过）**：

1. 目录在仓库 `skills/<名>/` **一级位置**，含 `SKILL.md`，frontmatter 有 `name` 和带触发词的 `description`。tap 只扫这一层，嵌套类别目录扫不到。
2. **不写死某一台机器的绝对路径**（`~/Desktop/xxx`、`/Users/...`）。确实依赖本机文件的，写明"其他机器没有时怎么降级"，不能因为找不到文件就停。
3. 不含密钥、token、客户隐私、学号手机号。推前 `grep -rniE "token|secret|api[_-]?key|password" skills/<名>` 一遍。
4. `references/`、`assets/`、`scripts/` 用相对路径引用；脚本不依赖 agent 特有命令。
5. **通用能力才进源**；单 profile / 单项目专属流程留在本地。
6. 至少实跑一次（新会话让 agent 用它完成一个真实任务）。
7. 内容仓 README 的"收录的 Skill"表加一行。

运行依赖（第三方 token、API key）是机器级配置，看各 skill 自己 SKILL.md 的"配置"小节，不进仓库。

## 五、坑清单（实测）

1. **tap 只扫 `skills/` 一级目录**——放根目录或再嵌一层都扫不到。
2. **Hermes tap 安装是拷贝不是链接**——各端要主动 `update`；改安装拷贝会被覆盖。
3. **私有仓 raw 直链不可靠**——无鉴权 404。私有源走 `tap add`（用本机 gh 凭据）或 `sync.sh`（用 gh clone）。引导仓公开，raw 直链对它有效。
4. **Hermes profile 是独立拷贝**——全局装了 ≠ profile 能用，要 `hermes -p <名> skills install`。
5. **装了 ≠ 能跑**——密钥类配置是机器级的。
6. **备份不要放技能目录里**——`~/.claude/skills/xxx.bak/` 里的 SKILL.md 会被当成同名 skill 加载。`sync.sh` 的备份在 `~/.hermes-skill-sync/backups/`。
7. **软链模式下工作副本就是活的源**——在 `~/.claude/skills/<名>/` 里改文件等于改工作副本，改完记得 commit + push，否则其他机器拿不到。
8. **community 来源先 `hermes skills inspect` 再装**，别随手 `--force`。

## 六、接入验证清单

- [ ] 两个工作副本存在，`git -C <路径> status` 干净
- [ ] Hermes：`hermes skills tap list` 两条 flowstart 源，`hermes skills search <skill名>` 能搜到，`~/.hermes/skills/<名>/` 存在
- [ ] 其他 agent：`sync.sh --target <agent> --check` 全部 `linked`（或 `copied`）
- [ ] 开新会话，agent 的 skill 列表里能看到装的 skill；给它一个该 skill 描述里的触发句，它会用
- [ ] 实跑该 skill 的一个最小任务（各 skill 自述里有）
