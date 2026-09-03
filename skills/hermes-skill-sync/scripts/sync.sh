#!/usr/bin/env bash
# sync.sh — 把 skill 统一源（flowstart/hermes-skills）接入到 Claude Code / Codex / OpenClaw
#
# 用法：
#   sync.sh --target claude|codex|openclaw (--all | --skill NAME [--skill NAME2 ...])
#           [--mode link|copy] [--check] [--dry-run] [--no-pull] [--workspace DIR] [--source DIR]
#
# 做的事（幂等，可反复跑）：
#   1. 保证两个工作副本存在且是最新：内容仓 $SOURCE、引导仓 $BOOTSTRAP（不存在就 clone，存在就 pull）
#   2. 把选中的 skill（+ 引导 skill 本身）软链/拷贝到目标 agent 的技能目录
#   3. --check 只报告状态不改动
#
# 环境变量：HERMES_SKILLS_DIR（内容仓路径）、HERMES_SKILL_SYNC_DIR（引导仓路径）
set -euo pipefail

CONTENT_REPO="flowstart/hermes-skills"
BOOTSTRAP_REPO="flowstart/hermes-skill-sync"
SOURCE="${HERMES_SKILLS_DIR:-$HOME/Desktop/GitHub/hermes-skills}"
BOOTSTRAP="${HERMES_SKILL_SYNC_DIR:-$HOME/Desktop/GitHub/hermes-skill-sync}"
BACKUP_ROOT="$HOME/.hermes-skill-sync/backups"

TARGET=""; MODE="link"; ALL=0; CHECK=0; DRY=0; NOPULL=0; WORKSPACE=""
SKILLS=()

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    TARGET="$2"; shift 2;;
    --skill)     SKILLS+=("$2"); shift 2;;
    --all)       ALL=1; shift;;
    --mode)      MODE="$2"; shift 2;;
    --check)     CHECK=1; shift;;
    --dry-run)   DRY=1; shift;;
    --no-pull)   NOPULL=1; shift;;
    --workspace) WORKSPACE="$2"; shift 2;;
    --source)    SOURCE="$2"; shift 2;;
    -h|--help)   usage 0;;
    *) die "未知参数: $1（-h 看用法）";;
  esac
done

[ -n "$TARGET" ] || usage 1
case "$MODE" in link|copy) ;; *) die "--mode 只能是 link 或 copy";; esac

# ---- 目标 agent 的技能目录 ----
openclaw_workspace() {
  [ -n "$WORKSPACE" ] && { printf '%s' "$WORKSPACE"; return; }
  local cfg="$HOME/.openclaw/openclaw.json" ws=""
  if [ -f "$cfg" ] && command -v python3 >/dev/null 2>&1; then
    ws=$(python3 - "$cfg" <<'PY' 2>/dev/null || true
import json,sys
def find(o):
    if isinstance(o,dict):
        for k,v in o.items():
            if k=="workspace" and isinstance(v,str): return v
            r=find(v)
            if r: return r
    if isinstance(o,list):
        for v in o:
            r=find(v)
            if r: return r
try: print(find(json.load(open(sys.argv[1]))) or "")
except Exception: print("")
PY
)
  fi
  printf '%s' "${ws:-$HOME/.openclaw/workspace}"
}

case "$TARGET" in
  claude)   DEST="$HOME/.claude/skills";;
  codex)    DEST="$HOME/.codex/skills";;
  openclaw) DEST="$(openclaw_workspace)/skills";;
  hermes)   die "Hermes 请用 CLI：hermes skills tap add $CONTENT_REPO && hermes skills install $CONTENT_REPO/<skill> --yes";;
  *)        die "未知 --target: $TARGET（claude|codex|openclaw）";;
esac

realdir() { (cd "$1" 2>/dev/null && pwd -P) || printf ''; }

# ---- 保证工作副本存在且最新 ----
ensure_repo() {  # $1=repo  $2=path  $3=private(0/1)
  local repo="$1" path="$2" private="$3"
  if [ ! -d "$path/.git" ]; then
    [ "$CHECK" = 1 ] && { warn "工作副本不存在: $path（去掉 --check 让脚本 clone）"; return 1; }
    log "clone $repo -> $path"
    [ "$DRY" = 1 ] && return 0
    mkdir -p "$(dirname "$path")"
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      gh repo clone "$repo" "$path" -- -q
    elif [ "$private" = 1 ]; then
      die "$repo 是私有仓，需要 GitHub 凭据。先 gh auth login（选 HTTPS → Login with a web browser，屏幕出 8 位码，让用户手机打开 https://github.com/login/device 输码），再重跑。"
    else
      git clone -q "https://github.com/$repo.git" "$path"
    fi
  elif [ "$NOPULL" = 0 ] && [ "$DRY" = 0 ]; then
    if ! git -C "$path" pull -q --ff-only 2>/dev/null; then
      warn "$path pull 失败（有本地改动或网络问题），继续用当前版本"
    fi
  fi
}

ensure_repo "$BOOTSTRAP_REPO" "$BOOTSTRAP" 0 || true
ensure_repo "$CONTENT_REPO" "$SOURCE" 1 || true
[ -d "$SOURCE/skills" ] || die "内容仓不可用: $SOURCE/skills 不存在"

# ---- 选 skill ----
list_skills() { local d; for d in "$SOURCE"/skills/*/; do [ -f "$d/SKILL.md" ] && basename "$d"; done; }
if [ "$ALL" = 1 ]; then
  SKILLS=(); while IFS= read -r s; do SKILLS+=("$s"); done < <(list_skills)
fi
[ "${#SKILLS[@]}" -gt 0 ] || [ "$CHECK" = 1 ] || die "没有选 skill：用 --all 或 --skill NAME。可选：$(list_skills | tr '\n' ' ')"

# ---- 安装 / 检查一个 skill ----
status_of() {  # $1=name $2=src → 打印状态
  local dest="$DEST/$1" src="$2"
  if [ -L "$dest" ]; then
    [ "$(realdir "$dest")" = "$(realdir "$src")" ] && printf 'linked' || printf 'foreign-link'
  elif [ -d "$dest" ]; then
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then printf 'copied'; else printf 'copied-stale'; fi
  else printf 'missing'; fi
}

install_one() {  # $1=name $2=src
  local name="$1" src="$2" dest="$DEST/$1" st
  [ -f "$src/SKILL.md" ] || { warn "$name: 源里没有 SKILL.md，跳过"; return; }
  st=$(status_of "$name" "$src")
  if [ "$CHECK" = 1 ]; then log "  $name: $st"; return; fi
  if [ "$MODE" = link ]; then
    case "$st" in
      linked) log "  $name: ok (linked)"; return;;
      copied|copied-stale|foreign-link)
        local bk="$BACKUP_ROOT/$TARGET/$name-$(date +%Y%m%d-%H%M%S)"
        log "  $name: 目标已存在（$st）→ 备份到 $bk 后改为软链"
        [ "$DRY" = 1 ] || { mkdir -p "$(dirname "$bk")"; mv "$dest" "$bk"; };;
      missing) log "  $name: linked";;
    esac
    [ "$DRY" = 1 ] || ln -sfn "$(realdir "$src")" "$dest"
  else
    case "$st" in
      copied) log "  $name: ok (copied, up to date)"; return;;
      linked|foreign-link) log "  $name: 目标是软链 → 换成拷贝"; [ "$DRY" = 1 ] || rm -f "$dest";;
      copied-stale) log "  $name: copied (refreshed)";;
      missing) log "  $name: copied";;
    esac
    [ "$DRY" = 1 ] || { rm -rf "$dest"; cp -R "$(realdir "$src")" "$dest"; }
  fi
}

[ "$DRY" = 1 ] && log "(dry-run，不做任何改动)"
log "目标: $TARGET → $DEST   模式: $MODE   内容仓: $SOURCE"
[ "$DRY" = 1 ] || [ "$CHECK" = 1 ] || mkdir -p "$DEST"

# 引导 skill 自身永远一起装（它就是 runbook）
if [ -f "$BOOTSTRAP/skills/hermes-skill-sync/SKILL.md" ]; then
  install_one hermes-skill-sync "$BOOTSTRAP/skills/hermes-skill-sync"
fi
if [ "$CHECK" = 1 ] && [ "${#SKILLS[@]}" -eq 0 ]; then
  SKILLS=(); while IFS= read -r s; do SKILLS+=("$s"); done < <(list_skills)
fi
for s in "${SKILLS[@]}"; do
  [ -d "$SOURCE/skills/$s" ] || { warn "$s: 内容仓里没有这个 skill（可选：$(list_skills | tr '\n' ' ')）"; continue; }
  install_one "$s" "$SOURCE/skills/$s"
done

[ "$CHECK" = 1 ] && exit 0
log ""
case "$TARGET" in
  claude)   log "生效：Claude Code 新会话自动识别；skill 列表里应看到上面的名字。";;
  codex)    log "生效：Codex 新会话按 description 自动匹配，或用 \$<skill名> 显式调用。";;
  openclaw) log "生效：OpenClaw 重载 workspace（或重启网关）后可用。";;
esac
log "更新：以后只需重跑同一条命令（link 模式下 pull 即生效，重跑是为了补新入源的 skill）。"
