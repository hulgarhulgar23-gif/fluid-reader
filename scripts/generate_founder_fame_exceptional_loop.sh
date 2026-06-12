#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame exceptional loop from live ledger data or founder KPI artifacts.

Usage:
  zsh scripts/generate_founder_fame_exceptional_loop.sh [options]

Optional:
  --ledger <path>                 Fame snapshot ledger markdown (default: ~/Documents/FluidReader/FameSnapshots/fame-snapshot-ledger.md)
  --kpi-snapshot <path>           Founder fame KPI snapshot markdown (used when ledger is unavailable)
  --velocity-scoreboard <path>    Founder fame velocity scoreboard markdown (used when ledger is unavailable)
  --week <label>                  Week label override (default: inferred from latest ledger timestamp, then current ISO week)
  --window <count>                Number of latest rows to analyze (default: 12)
  --momentum-floor <score>        Score threshold for momentum streak (default: 75)
  --elite-floor <score>           Score threshold for elite streak (default: 85)
  --product <text>                Product name (default: Fluid Reader)
  --out <path>                    Output path (default: docs/campaigns/<week>-founder-fame-exceptional-loop.md)
  -h, --help                      Show help

Example:
  zsh scripts/generate_founder_fame_exceptional_loop.sh \
    --ledger "$HOME/Documents/FluidReader/FameSnapshots/fame-snapshot-ledger.md" \
    --window 14 \
    --out docs/campaigns/2026-W24-founder-fame-exceptional-loop.md

  zsh scripts/generate_founder_fame_exceptional_loop.sh \
    --kpi-snapshot docs/campaigns/2026-W24-founder-fame-kpi-snapshot.md \
    --velocity-scoreboard docs/campaigns/2026-W24-founder-fame-velocity-scoreboard.md \
    --out docs/campaigns/2026-W24-founder-fame-exceptional-loop.md
EOF
}

ledger_path="${HOME}/Documents/FluidReader/FameSnapshots/fame-snapshot-ledger.md"
kpi_snapshot_path=""
velocity_scoreboard_path=""
week_label=""
window_size=12
momentum_floor=75
elite_floor=85
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --ledger)
      ledger_path="${2:-}"
      shift 2
      ;;
    --kpi-snapshot)
      kpi_snapshot_path="${2:-}"
      shift 2
      ;;
    --velocity-scoreboard)
      velocity_scoreboard_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --window)
      window_size="${2:-}"
      shift 2
      ;;
    --momentum-floor)
      momentum_floor="${2:-}"
      shift 2
      ;;
    --elite-floor)
      elite_floor="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for pair in \
  "window_size:$window_size" \
  "momentum_floor:$momentum_floor" \
  "elite_floor:$elite_floor"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ ! "$value" =~ '^[0-9]+$' ]] || (( value <= 0 )); then
    echo "Expected positive integer for ${key}, got: ${value}" >&2
    exit 1
  fi
done

if (( elite_floor < momentum_floor )); then
  echo "--elite-floor must be >= --momentum-floor." >&2
  exit 1
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

sanitize_inline() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  value="${value//|//}"
  value="${value//\`/}"
  trim_value "$value"
}

default_if_blank() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

lowercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
}

resolve_week_from_stamp() {
  local stamp="$1"
  local week
  week="$(date -j -f '%Y%m%d-%H%M' "$stamp" '+%Y-W%V' 2>/dev/null || true)"
  if [[ -n "$week" ]]; then
    echo "$week"
    return
  fi
  date '+%Y-W%V'
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_week_from_heading_prefix() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi
  local heading
  heading="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"$prefix"}"
}

extract_first_integer() {
  local raw="$1"
  local value
  value="$(print -r -- "$raw" | rg -o --pcre2 '[0-9]+' | head -n1 || true)"
  echo "$value"
}

format_score() {
  local value="$1"
  awk -v value="$value" 'BEGIN { printf "%.1f", value + 0 }'
}

format_signed_score() {
  local value="$1"
  awk -v value="$value" 'BEGIN { adjusted = value + 0; if (adjusted > 0) printf "+%.1f", adjusted; else printf "%.1f", adjusted }'
}

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

source_mode="ledger"
if [[ ! -f "$ledger_path" ]]; then
  source_mode="artifacts"
fi
source_ledger_display="n/a"

if [[ -n "$kpi_snapshot_path" && ! -f "$kpi_snapshot_path" ]]; then
  echo "KPI snapshot file not found: $kpi_snapshot_path" >&2
  exit 1
fi

if [[ -n "$velocity_scoreboard_path" && ! -f "$velocity_scoreboard_path" ]]; then
  echo "Velocity scoreboard file not found: $velocity_scoreboard_path" >&2
  exit 1
fi

if [[ "$source_mode" == "artifacts" ]] && { [[ -z "$kpi_snapshot_path" ]] || [[ -z "$velocity_scoreboard_path" ]]; }; then
  echo "Ledger missing. Provide both --kpi-snapshot and --velocity-scoreboard." >&2
  exit 1
fi

row_count=0
window_count=0
latest_stamp=""
latest_stage=""
latest_day="n/a"
latest_score_raw=0
window_average_raw=0
window_velocity_raw=0
window_volatility_raw=0
momentum_streak=0
elite_streak=0
best_stage="n/a"
route_mode="Stabilize"
readiness="Foundation Reset"
stability_band="Watchlist"

if [[ "$source_mode" == "ledger" ]]; then
  source_ledger_display="$ledger_path"
  rows_tmp="$(mktemp "${TMPDIR:-/tmp}/founder-fame-exceptional-loop-rows.XXXXXX")"
  window_tmp="$(mktemp "${TMPDIR:-/tmp}/founder-fame-exceptional-loop-window.XXXXXX")"
  cleanup() {
    rm -f "$rows_tmp" "$window_tmp"
  }
  trap cleanup EXIT

  awk -F'|' '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 ~ /^\|/ {
      timestamp = clean($2)
      stage = clean($3)
      score = clean($4)
      day = clean($5)
      if (timestamp == "Timestamp" || timestamp == "---" || timestamp == "") next
      gsub(/[^0-9.+-]/, "", score)
      if (score == "") next
      if (stage == "") stage = "n/a"
      if (day == "") day = "n/a"
      print timestamp "\t" stage "\t" score "\t" day
    }
  ' "$ledger_path" > "$rows_tmp"

  row_count="$(wc -l < "$rows_tmp" | tr -d ' ')"
  if [[ -z "$row_count" || "$row_count" == "0" ]]; then
    echo "No ledger rows found in: $ledger_path" >&2
    exit 1
  fi

  window_count="$window_size"
  if (( row_count < window_count )); then
    window_count="$row_count"
  fi
  tail -n "$window_count" "$rows_tmp" > "$window_tmp"

  latest_stamp="$(tail -n 1 "$window_tmp" | cut -f1)"
  latest_stage="$(tail -n 1 "$window_tmp" | cut -f2)"
  latest_score_raw="$(tail -n 1 "$window_tmp" | cut -f3)"
  latest_day="$(tail -n 1 "$window_tmp" | cut -f4)"

  first_score_raw="$(head -n 1 "$window_tmp" | cut -f3)"
  window_average_raw="$(awk -F'\t' '{ sum += $3; count++ } END { if (count == 0) print "0"; else printf "%.3f", sum / count }' "$window_tmp")"
  window_velocity_raw="$(awk -v first="$first_score_raw" -v last="$latest_score_raw" 'BEGIN { printf "%.3f", (last + 0) - (first + 0) }')"
  window_volatility_raw="$(awk -F'\t' '
    BEGIN { count = 0; sum = 0 }
    { values[count] = $3 + 0; sum += $3 + 0; count++ }
    END {
      if (count <= 1) {
        printf "%.3f", 0
        exit
      }
      mean = sum / count
      variance = 0
      for (idx = 0; idx < count; idx++) {
        delta = values[idx] - mean
        variance += (delta * delta)
      }
      variance /= count
      printf "%.3f", sqrt(variance)
    }
  ' "$window_tmp")"

  momentum_streak="$(tail -r "$window_tmp" | awk -F'\t' -v floor="$momentum_floor" '
    {
      score = $3 + 0
      if (score >= floor) {
        streak++
      } else {
        exit
      }
    }
    END { print streak + 0 }
  ')"

  elite_streak="$(tail -r "$window_tmp" | awk -F'\t' -v floor="$elite_floor" '
    {
      score = $3 + 0
      if (score >= floor) {
        streak++
      } else {
        exit
      }
    }
    END { print streak + 0 }
  ')"

  best_stage="$(awk -F'\t' '
    BEGIN { bestScore = -1000000; bestStage = "n/a" }
    {
      score = $3 + 0
      if (score >= bestScore) {
        bestScore = score
        bestStage = $2
      }
    }
    END { print bestStage }
  ' "$window_tmp")"

  route_mode="$(awk \
    -v latest="$latest_score_raw" \
    -v velocity="$window_velocity_raw" \
    -v volatility="$window_volatility_raw" \
    -v momentum="$momentum_floor" '
    BEGIN {
      if (latest < 60 || velocity < -8) {
        print "Recovery"
        exit
      }
      if (latest < momentum || velocity < 0 || volatility > 9) {
        print "Stabilize"
        exit
      }
      print "Accelerate"
    }
  ')"

  readiness="$(awk \
    -v latest="$latest_score_raw" \
    -v velocity="$window_velocity_raw" \
    -v elite="$elite_floor" \
    -v momentum="$momentum_floor" \
    -v eliteStreak="$elite_streak" \
    -v momentumStreak="$momentum_streak" '
    BEGIN {
      if (latest >= elite && velocity >= 0 && eliteStreak >= 3) {
        print "Breakout Ready"
        exit
      }
      if (latest >= momentum && velocity >= -2 && momentumStreak >= 2) {
        print "Momentum Building"
        exit
      }
      print "Foundation Reset"
    }
  ')"

  stability_band="$(awk -v volatility="$window_volatility_raw" '
    BEGIN {
      if (volatility <= 4) {
        print "Stable"
        exit
      }
      if (volatility <= 8) {
        print "Watchlist"
        exit
      }
      print "Volatile"
    }
  ')"
else
  velocity_score_line="$(extract_prefixed_value "$velocity_scoreboard_path" "- Velocity score: ")"
  if [[ -z "$velocity_score_line" ]]; then
    velocity_score_line="$(extract_prefixed_value "$velocity_scoreboard_path" "Velocity score: ")"
  fi
  velocity_score_raw="$(extract_first_integer "$velocity_score_line")"
  if [[ -z "$velocity_score_raw" ]]; then
    velocity_score_raw=70
  fi

  velocity_tier="$(extract_prefixed_value "$velocity_scoreboard_path" "- Tier: ")"
  route_kpi_mode="$(extract_prefixed_value "$velocity_scoreboard_path" "- Route KPI mode: ")"
  if [[ -z "$route_kpi_mode" ]]; then
    route_kpi_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Route KPI mode: ")"
  fi

  route_mode_signal="$(lowercase_value "${route_kpi_mode} ${velocity_tier}")"
  if print -r -- "$route_mode_signal" | rg -q -- 'recovery'; then
    route_mode="Recovery"
  elif print -r -- "$route_mode_signal" | rg -q -- '(re-lock|stabilize)'; then
    route_mode="Stabilize"
  else
    route_mode="Accelerate"
  fi

  case "$velocity_tier" in
    Scale)
      readiness="Breakout Ready"
      window_velocity_raw=6
      window_volatility_raw=3
      ;;
    Compound)
      readiness="Momentum Building"
      window_velocity_raw=2
      window_volatility_raw=5
      ;;
    Re-Lock)
      readiness="Foundation Reset"
      window_velocity_raw=-2
      window_volatility_raw=7
      ;;
    *)
      readiness="Foundation Reset"
      window_velocity_raw=-6
      window_volatility_raw=9
      ;;
  esac

  latest_stamp="$(date '+%Y%m%d-%H%M')"
  latest_stage="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative route winner: ")"
  if [[ -z "$latest_stage" ]]; then
    latest_stage="$(extract_prefixed_value "$kpi_snapshot_path" "- Top bet: ")"
  fi
  latest_stage="$(default_if_blank "$latest_stage" "n/a")"

  latest_score_raw="$velocity_score_raw"
  window_average_raw="$latest_score_raw"
  window_count=3
  row_count=3
  best_stage="$latest_stage"
  momentum_streak=0
  elite_streak=0
  if (( latest_score_raw >= momentum_floor )); then
    momentum_streak=1
  fi
  if (( latest_score_raw >= elite_floor )); then
    elite_streak=1
  fi

  if [[ "$route_mode" == "Recovery" ]]; then
    stability_band="Volatile"
  elif [[ "$route_mode" == "Stabilize" ]]; then
    stability_band="Watchlist"
  else
    stability_band="Stable"
  fi
fi

if [[ -z "$week_label" ]]; then
  if [[ "$source_mode" == "ledger" ]]; then
    week_label="$(resolve_week_from_stamp "$latest_stamp")"
  else
    week_label="$(extract_week_from_heading_prefix "$velocity_scoreboard_path" "# Founder Fame Velocity Scoreboard - ")"
    if [[ -z "$week_label" ]]; then
      week_label="$(extract_week_from_heading_prefix "$kpi_snapshot_path" "# Founder Fame KPI Snapshot - ")"
    fi
    if [[ -z "$week_label" ]]; then
      week_label="$(date '+%Y-W%V')"
    fi
  fi
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-exceptional-loop.md"
fi

latest_score="$(format_score "$latest_score_raw")"
window_average="$(format_score "$window_average_raw")"
window_velocity="$(format_signed_score "$window_velocity_raw")"
window_volatility="$(format_score "$window_volatility_raw")"

case "$route_mode" in
  Recovery)
    multiplier_one="Ship one proof artifact in the next 6 hours to stop score decay."
    multiplier_two="Close one narrative risk publicly with evidence before starting a new lane."
    multiplier_three="Use checklist comments as the single source of truth for owner status."
    horizon_0_focus="Contain risk + restore trust"
    horizon_1_focus="Prove consistency"
    horizon_2_focus="Return to compounding"
    ;;
  Stabilize)
    multiplier_one="Protect posting cadence: one proof move every 24 hours with explicit KPI linkage."
    multiplier_two="Promote one high-confidence clip into two channels with channel-specific CTA."
    multiplier_three="Escalate blockers within 2 hours when ownership is unclear."
    horizon_0_focus="Lock route and owner"
    horizon_1_focus="Double down on winner"
    horizon_2_focus="Convert proof into social lift"
    ;;
  *)
    multiplier_one="Compound the winning stage by replicating the same proof format across two channels."
    multiplier_two="Convert each artifact into one outreach touchpoint and one credibility update."
    multiplier_three="Preserve velocity by scheduling the next owner handoff before closeout."
    horizon_0_focus="Scale the winner"
    horizon_1_focus="Expand distribution"
    horizon_2_focus="Bank durable proof"
    ;;
esac

x_hook="Week ${week_label}: score ${latest_score} (${window_velocity} over last ${window_count} runs). Route mode is ${route_mode}; shipping the next proof move now."
linkedin_hook="Founder execution update (${week_label}): operating in ${route_mode} with ${readiness} status, anchored on stage '${latest_stage}' and measured against weekly score drift."
checklist_hook="Route mode: ${route_mode} | Readiness: ${readiness} | Latest score: ${latest_score} | Velocity(${window_count}): ${window_velocity}"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-exceptional-loop -->

# Founder Fame Exceptional Loop - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source ledger: ${source_ledger_display}
Source KPI snapshot: $(default_if_blank "${kpi_snapshot_path:-}" "n/a")
Source velocity scoreboard: $(default_if_blank "${velocity_scoreboard_path:-}" "n/a")
Rows analyzed: ${window_count} of ${row_count}

## Signal Snapshot

- Latest timestamp: ${latest_stamp}
- Latest stage: ${latest_stage}
- Latest day label: ${latest_day}
- Latest score: ${latest_score}
- Window average score: ${window_average}
- Window velocity (${window_count} runs): ${window_velocity}
- Window volatility (${window_count} runs): ${window_volatility} (${stability_band})
- Momentum streak (>=${momentum_floor}): ${momentum_streak}
- Elite streak (>=${elite_floor}): ${elite_streak}
- Best stage in window: ${best_stage}
- Route mode: ${route_mode}
- Exceptional readiness: ${readiness}

## 72-Hour Exceptional Loop

| Horizon | Focus | Action | KPI Guardrail |
| --- | --- | --- | --- |
| 0-24h | ${horizon_0_focus} | Publish one proof artifact tied to the current stage and push one owner update into checklist comments. | No skipped proof window; checklist status updated within the same day. |
| 24-48h | ${horizon_1_focus} | Repurpose the best-performing artifact into a second channel with a direct CTA and one outreach follow-up. | Velocity remains non-negative and score does not drop below ${momentum_floor}. |
| 48-72h | ${horizon_2_focus} | Convert proof into a durable asset (war room, credibility ledger, or spotlight pack) and assign next owner handoff. | Readiness stays at or above current state with a documented next move owner. |

## Fame Multipliers

1. ${multiplier_one}
2. ${multiplier_two}
3. ${multiplier_three}

## Public Narrative Hooks

- X draft seed: ${x_hook}
- LinkedIn draft seed: ${linkedin_hook}
- Checklist update seed: ${checklist_hook}

## Operator Marker Block

\`\`\`text
weekly-growth-founder-fame-exceptional-loop
week: $(sanitize_inline "$week_label")
route_mode: $(sanitize_inline "$route_mode")
readiness: $(sanitize_inline "$readiness")
latest_score: $(sanitize_inline "$latest_score")
window_average: $(sanitize_inline "$window_average")
window_velocity: $(sanitize_inline "$window_velocity")
momentum_streak: $(sanitize_inline "$momentum_streak")
elite_streak: $(sanitize_inline "$elite_streak")
\`\`\`
EOF

echo "Generated founder fame exceptional loop: $output_path"
