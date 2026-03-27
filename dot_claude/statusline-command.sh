#!/usr/bin/env bash
input=$(cat)

# ANSI color codes
reset="\033[0m"
bold_white="\033[1;37m"
bold_magenta="\033[1;35m"
bold_green="\033[1;32m"
bold_cyan="\033[1;36m"
bold_yellow="\033[1;33m"
dim_white="\033[2;37m"
magenta="\033[35m"
green="\033[32m"
cyan="\033[36m"
yellow="\033[33m"

connector() { printf "${dim_white}%s${reset}" "$1"; }
append() { [ -n "$out" ] && out="$out "; out="$out$1"; }

out=""

# ---------------------------------------------------------------------------
# Directory: repo-root-relative path if in a git repo, otherwise basename
# ---------------------------------------------------------------------------
git_root=$(git rev-parse --show-toplevel 2>/dev/null)
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$git_root" ]; then
  rel=$(pwd | sed "s|^${git_root}||; s|^/||")
  dir_display="$(basename "$git_root")${rel:+/$rel}"
else
  dir_display=$(basename "$PWD")
fi
append "$(printf "${bold_green}%s${reset}" "$dir_display")"

# ---------------------------------------------------------------------------
# Git branch + status flags (single awk pass over porcelain output)
# ---------------------------------------------------------------------------
if [ -n "$git_branch" ]; then
  append "$(connector 'on')"
  flags=$(git status --porcelain 2>/dev/null | awk '
    /^\?\?/                { u=1 }
    /^[MADRCU]|^.[MADRCU]/ { m=1 }
    END { if (u) printf "?"; if (m) printf "!" }
  ')
  branch_display="$(printf "${magenta}⎇${reset} ${bold_white}%s${reset}" "$git_branch")"
  [ -n "$flags" ] && branch_display="${branch_display}$(printf "${dim_white}[%s]${reset}" "$flags")"
  append "$branch_display"
fi

# ---------------------------------------------------------------------------
# Node version (only if project uses node)
# ---------------------------------------------------------------------------
for f in package.json .nvmrc .node-version; do
  [ -f "$PWD/$f" ] && {
    node_ver=$(node --version 2>/dev/null)
    if [ -n "$node_ver" ]; then
      append "$(connector 'via')"
      append "$(printf "${bold_green}⬢ %s${reset}" "$node_ver")"
    fi
    break
  }
done

# ---------------------------------------------------------------------------
# Go version (only if project uses go)
# ---------------------------------------------------------------------------
go_project=false
for f in go.mod go.sum Gopkg.toml; do
  [ -f "$PWD/$f" ] && go_project=true && break
done
if ! $go_project; then
  set -- "$PWD"/*.go
  [ -f "$1" ] && go_project=true
fi
if $go_project; then
  go_ver=$(go version 2>/dev/null | awk '{sub(/^go/, "v", $3); print $3}')
  if [ -n "$go_ver" ]; then
    append "$(connector 'via')"
    append "$(printf "${bold_cyan}🐹 %s${reset}" "$go_ver")"
  fi
fi

# ---------------------------------------------------------------------------
# Python version/venv (only if project uses python)
# ---------------------------------------------------------------------------
py_project=false
for f in requirements.txt Pipfile pyproject.toml setup.py setup.cfg .python-version; do
  [ -f "$PWD/$f" ] && py_project=true && break
done
if ! $py_project; then
  set -- "$PWD"/*.py
  [ -f "$1" ] && py_project=true
fi
if $py_project; then
  active_venv="${VIRTUAL_ENV:-$PYENV_VIRTUAL_ENV}"
  if [ -n "$active_venv" ]; then
    append "$(connector 'via')"
    append "$(printf "${bold_yellow}🐍 (%s)${reset}" "$(basename "$active_venv")")"
  else
    py_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
    [ -z "$py_ver" ] && py_ver=$(python --version 2>/dev/null | awk '{print $2}')
    if [ -n "$py_ver" ]; then
      append "$(connector 'via')"
      append "$(printf "${bold_yellow}🐍 v%s${reset}" "$py_ver")"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Claude: "using Sonnet 4.6 with 18% context and $0.75" (API billing)
#      or "using Sonnet 4.6 with 18% context and 5h:12% | 7d:4%" (Pro/subscription)
# All fields extracted in a single jq call.
# ---------------------------------------------------------------------------
{ read -r model_display; read -r used_pct; read -r cost_usd; read -r limit_5h; read -r limit_7d; } < <(
  echo "$input" | jq -r '
    (.model.display_name // .model.id // ""),
    (.context_window.used_percentage // ""),
    (.cost.total_cost_usd // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  '
)

model_short=$(echo "$model_display" | awk '{
  gsub(/^[Cc]laude[- ]/, ""); gsub(/-/, " ")
  for (i=1; i<=NF; i++) $i = toupper(substr($i,1,1)) substr($i,2)
  print
}')

if [ -n "$model_short" ]; then
  append "$(connector 'using')"
  append "$(printf "${bold_magenta}🤖 %s${reset}" "$model_short")"

  if [ -n "$used_pct" ]; then
    append "$(connector 'with')"
    append "$(printf "💭 ${bold_white}$(printf '%.0f' "$used_pct")%% context${reset}")"
  fi

  # Show cost on API/enterprise billing, or plan usage on Pro/subscription
  if [ -n "$cost_usd" ] && awk "BEGIN{exit !($cost_usd > 0)}"; then
    append "$(connector 'cost')"
    append "$(printf "${bold_yellow}💰 \$%.2f${reset}" "$cost_usd")"
  elif [ -n "$limit_5h" ] || [ -n "$limit_7d" ]; then
    append "$(connector 'used')"
    limits=""
    [ -n "$limit_5h" ] && limits="$(printf "${bold_white}5h:$(printf '%.0f' "$limit_5h")%%${reset}")"
    if [ -n "$limit_7d" ]; then
      [ -n "$limits" ] && limits="$limits $(printf "${dim_white}|${reset}") "
      limits="${limits}$(printf "${bold_white}7d:$(printf '%.0f' "$limit_7d")%%${reset}")"
    fi
    append "$(printf "📊 %s" "$limits")"
  fi
fi

printf "%b" "$out"
