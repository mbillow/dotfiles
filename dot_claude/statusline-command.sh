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

connector() { printf "${dim_white}%s${reset}" "$1"; }
append() { [ -n "$out" ] && out="$out "; out="$out$1"; }

# Returns true if any of the given marker files exist in PWD,
# or if any files matching the glob (last arg, prefixed with *) exist.
has_project_files() {
  local ext="$1"; shift
  for f in "$@"; do [ -f "$PWD/$f" ] && return 0; done
  set -- "$PWD"/*."$ext"
  [ -f "$1" ]
}

# Returns ANSI color code for a usage percentage.
usage_color() {
  awk -v pct="$1" 'BEGIN {
    if      (pct >= 90) print "\033[1;31m"  # red
    else if (pct >= 75) print "\033[1;33m"  # bold yellow (closest to orange in 16-color)
    else if (pct >= 50) print "\033[33m"    # yellow
    else                print "\033[1;32m"  # green
  }'
}

# Formats a rate-limit badge: "5h[20%]" with colored percentage.
format_limit() {
  local label="$1" raw="$2"
  local pct col
  pct=$(printf '%.0f' "$raw")
  col=$(usage_color "$pct")
  printf "${bold_white}%s[${reset}${col}%s%%${reset}${bold_white}]${reset}" "$label" "$pct"
}

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
if has_project_files go go.mod go.sum Gopkg.toml; then
  go_ver=$(go version 2>/dev/null | awk '{sub(/^go/, "v", $3); print $3}')
  if [ -n "$go_ver" ]; then
    append "$(connector 'via')"
    append "$(printf "${bold_cyan}🐹 %s${reset}" "$go_ver")"
  fi
fi

# ---------------------------------------------------------------------------
# Python version/venv (only if project uses python)
# ---------------------------------------------------------------------------
if has_project_files py requirements.txt Pipfile pyproject.toml setup.py setup.cfg .python-version; then
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
# Claude: "using Sonnet 4.6 with 18% context and 5h[12%] 7d[4%]" (Pro/subscription)
#      or "using Sonnet 4.6 with 18% context and $0.75" (API/enterprise billing)
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
    append "$(printf "🌀 ${bold_cyan}$(printf '%.0f' "$used_pct")%% context${reset}")"
  fi

  # Show plan usage on Pro/subscription; fall back to $ cost on API/enterprise billing
  if [ -n "$limit_5h" ] || [ -n "$limit_7d" ]; then
    append "$(connector 'used')"
    limits=""
    [ -n "$limit_5h" ] && limits="$(format_limit '5h' "$limit_5h")"
    if [ -n "$limit_7d" ]; then
      [ -n "$limits" ] && limits="$limits "
      limits="${limits}$(format_limit '7d' "$limit_7d")"
    fi
    append "$(printf "📊 %s" "$limits")"
  elif [ -n "$cost_usd" ] && awk "BEGIN{exit !($cost_usd > 0)}"; then
    append "$(connector 'cost')"
    append "$(printf "${bold_yellow}💰 \$%.2f${reset}" "$cost_usd")"
  fi
fi

printf "%b" "$out"
