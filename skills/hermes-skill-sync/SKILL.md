---
name: hermes-skill-sync
description: 自建 skill 统一源的分发与运维指南（引导 skill）。装了它，agent 就知道如何接入 skill 源（tap add flowstart/hermes-skills）、批量安装、日常更新、修改规范、新增 skill 入源规范，以及全部实测坑（tap 只扫一层/拷贝非链接/私有仓库凭据/raw URL 不可靠/运行依赖配置）。触发词：接入skill源、skill同步、安装skill、hermes-skills、统一真源。
---

# Hermes Skill 统一源 · 接入与运维

本 skill 是"自建 skill 统一源"体系的**引导入口**。读完并按此执行，任何一台新机器上的 Hermes 都能接入同一套 skill 体系，并且知道日后怎么维护。

## 一、体系架构（两个仓库，各司其职）

| 仓库 | 角色 | 内容 |
|---|---|---|
| `flowstart/hermes-skill-sync`（本仓库） | **引导 + 规范** | 本 skill：接入方法、运维规范、坑清单 |
| `flowstart/hermes-skills`（私有） | **内容真源** | 实际的业务 skill（如抖音博主蒸馏套件） |

两个仓库都要 `tap add`（见下）。skill 的**修改只发生在本地工作副本 → push**，各端只 `update`，**严禁直接改安装拷贝**（会被下次 update 覆盖）。

## 二、新机器接入（Runbook）

```bash
# 0. 前提：Hermes 已装（hermes --version 可用）；GitHub 凭据已配
#    推荐本机终端 gh auth login（keyring 认证，私有仓库必需）
#    国内服务器先确认 curl -I https://api.github.com 通（不通先配代理）

# 1. 挂载两个源
hermes skills tap add flowstart/hermes-skill-sync
hermes skills tap add flowstart/hermes-skills
hermes skills tap list   # 应看到两条

# 2. 验证可发现
hermes skills search douyin-blogger-distill

# 3. 安装引导 skill（本 skill）+ 需要的内容 skill
hermes skills install flowstart/hermes-skill-sync/hermes-skill-sync --yes
hermes skills install flowstart/hermes-skills/<skill名> --yes

# 4. 某 profile 也要用 → 逐个装
hermes -p <profile名> skills install flowstart/hermes-skills/<skill名> --yes
```

### 运行依赖（装完 skill 必须单独配，否则跑不了）
- **TikHub token**（抖音抓取/下载）：`~/.openclaw/config.json` 加 `"tikhub_api_token": "<向源机器索取>"`
- **Get笔记**（长视频转录）：`~/.openclaw/openclaw.json` 的 `skills.entries.getnote`（`apiKey` + `env.GETNOTE_CLIENT_ID`）
- 其他 skill 的依赖看其 SKILL.md 的"配置"小节

## 三、日常运维

```bash
hermes skills check && hermes skills update   # 各端定期拉齐
hermes skills audit                           # 审计
hermes curator status                         # 生命周期（归档/备份），永不删除
```

修改/新增 skill 的唯一正确姿势：

```bash
cd <本地工作副本，如 ~/Desktop/GitHub/hermes-skills/skills/<skill名>/>
# 改 SKILL.md 或 scripts/…
git add -A && git commit -m "feat: xxx" && git push
# 然后各端：hermes skills check && hermes skills update
```

**新增 skill 入源规范**：目录必须放在仓库的 `skills/<skill名>/` **一级位置**（tap 只扫这一层！）；SKILL.md 必填 name/description；实现脚本放该目录 `scripts/`；**通用能力才进源**，单 profile 专属流程留在本地。

## 四、坑清单（全部实测踩过）

1. **tap 只扫 `skills/` 下的一级目录**——skill 放仓库根目录、或再嵌套类别子目录，都扫不到。
2. **tap 安装是拷贝不是链接**——没有自动同步，分叉要靠"改源→push→各端 update"治理。
3. **私有仓库凭据**——raw.githubusercontent.com 直链安装对私有仓库**不可靠**（无鉴权会 404），私有源一律走 `tap add`（走本机 gh/keyring 鉴权）+ 按 identifier 安装。
4. **profile 是独立拷贝**——装到全局层不等于 profile 能用，跨 profile 要 `hermes -p <名> skills install …`。
5. **装了 ≠ 能跑**——密钥类配置是机器级的，见"运行依赖"。
6. **安全边界**——community 来源先 `hermes skills inspect` 再装，别随手 `--force`；危险命令还有审批模式兜底。

## 五、接入验证清单

- [ ] `hermes skills tap list` 有两个 flowstart 源
- [ ] `hermes skills search` 能搜到内容 skill
- [ ] 安装后 `~/.hermes/skills/` 下有 skill 目录（含 scripts/）
- [ ] 实跑一条核心命令验证（如 `douyin_user_distill.py "<博主主页链接>" --max-works 5` 能出档案）
- [ ] `hermes skills check && hermes skills update` 正常
