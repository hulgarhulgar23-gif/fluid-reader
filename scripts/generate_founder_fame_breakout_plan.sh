#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame breakout plan from spotlight and execution artifacts.

Usage:
  zsh scripts/generate_founder_fame_breakout_plan.sh [options]

Required:
  --spotlight-pack <path>          Founder fame spotlight pack markdown

Optional:
  --command-center <path>          Founder fame command center markdown
  --execution-sprint <path>        Founder fame execution sprint markdown
  --distribution-plan <path>       7-day distribution follow-up plan markdown
  --winning-hook-library <path>    Winning hook library markdown
  --credibility-ledger <path>      Credibility ledger markdown
  --week <label>                   Week label (default: inferred from spotlight heading, then current ISO week)
  --product <text>                 Product name (default: Fluid Reader)
  --primary-channel <text>         Primary publishing channel (default: X / Threads)
  --backup-channel <text>          Backup publishing channel (default: LinkedIn)
  --cta <text>                     CTA line for scripts
  --out <path>                     Output path (default: docs/campaigns/<week>-founder-fame-breakout-plan.md)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_fame_breakout_plan.sh \
    --spotlight-pack docs/campaigns/2026-W24-founder-fame-spotlight-pack.md \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --execution-sprint docs/campaigns/2026-W24-founder-fame-execution-sprint.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --winning-hook-library docs/campaigns/2026-W24-winning-hook-library.md \
    --credibility-ledger docs/campaigns/2026-W24-credibility-ledger.md \
    --out docs/campaigns/2026-W24-founder-fame-breakout-plan.md
EOF
}

spotlight_pack_path=""
command_center_path=""
execution_sprint_path=""
distribution_plan_path=""
winning_hook_library_path=""
credibility_ledger_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="Reply with your KPI bottleneck and I will share the exact command stack."
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --spotlight-pack)
      spotlight_pack_path="${2:-}"
      shift 2
      ;;
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --execution-sprint)
      execution_sprint_path="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
      shift 2
      ;;
    --winning-hook-library)
      winning_hook_library_path="${2:-}"
      shift 2
      ;;
    --credibility-ledger)
      credibility_ledger_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
      shift 2
      ;;
    --primary-channel)
      primary_channel="${2:-}"
      shift 2
      ;;
    --backup-channel)
      backup_channel="${2:-}"
      shift 2
      ;;
    --cta)
      cta_text="${2:-}"
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

if [[ -z "$spotlight_pack_path" ]]; then
  echo "Missing required option: --spotlight-pack" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$spotlight_pack_path" ]]; then
  echo "Required source file not found: $spotlight_pack_path" >&2
  exit 1
fi

for optional_path in \
  "$command_center_path" \
  "$execution_sprint_path" \
  "$distribution_plan_path" \
  "$winning_hook_library_path" \
  "$credibility_ledger_path"; do
  if [[ -n "$optional_path" && ! -f "$optional_path" ]]; then
    echo "Optional source file not found: $optional_path" >&2
    exit 1
  fi
done

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

sanitize_inline() {
  local value="$1"
  value="${value//$'\n'/ }"
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

resolve_outreach_lane_strategy() {
  local creator_lane_raw="$1"
  local outreach_recommendation_raw="$2"
  local combined
  combined="$(lowercase_value "${creator_lane_raw} ${outreach_recommendation_raw}")"

  if print -r -- "$combined" | rg -q -- '(creator[- ]first|creator[- ]led|creator[- ]heavy|creator[- ]priority|focus creator)'; then
    echo "creator-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- '(guesting[- ]first|guesting[- ]led|guesting[- ]heavy|guesting[- ]priority|focus guesting|founder guesting)'; then
    echo "guesting-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- 'creator' && ! print -r -- "$combined" | rg -q -- 'guesting'; then
    echo "creator-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- 'guesting' && ! print -r -- "$combined" | rg -q -- 'creator'; then
    echo "guesting-led"
    return
  fi

  echo "balanced"
}

extract_heading() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi

  local heading
  heading="$(rg -m1 '^# ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo "n/a"
    return
  fi
  echo "${heading#\# }"
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

extract_rg_match() {
  local source_path="$1"
  local pattern="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  rg -m1 -- "$pattern" "$source_path" || true
}

extract_section_prefixed_value() {
  local source_path="$1"
  local section_heading="$2"
  local prefix="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -v heading="$section_heading" -v prefix="$prefix" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^### / && heading !~ /^### / { next }
    in_section {
      if (index($0, prefix) == 1) {
        value = substr($0, length(prefix) + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        print value
        exit
      }
    }
  ' "$source_path"
}

extract_table_cell_by_first_column() {
  local source_path="$1"
  local section_heading="$2"
  local first_column_value="$3"
  local column_index="$4"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="$section_heading" -v row="$first_column_value" -v col="$column_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Day" || first == "Rank" || first == "Loop" || first == "Dimension" || first == "Priority" || first ~ /^---/) next
      if (first == row) {
        idx = col + 1
        value = clean($(idx))
        print value
        exit
      }
    }
  ' "$source_path"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$spotlight_pack_path" "# Founder Fame Spotlight Pack - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$command_center_path" "# Founder Fame Command Center - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-breakout-plan.md"
fi

mkdir -p "$(dirname "$output_path")"

spotlight_heading="$(extract_heading "$spotlight_pack_path")"
command_center_heading="$(extract_heading "$command_center_path")"
execution_sprint_heading="$(extract_heading "$execution_sprint_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
winning_hook_heading="$(extract_heading "$winning_hook_library_path")"
credibility_heading="$(extract_heading "$credibility_ledger_path")"

top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
if [[ -z "$top_bet" ]]; then
  top_bet="$(extract_prefixed_value "$spotlight_pack_path" "- Top bet: ")"
fi
fame_readiness="$(extract_prefixed_value "$command_center_path" "- Fame readiness: ")"
if [[ -z "$fame_readiness" ]]; then
  fame_readiness="$(extract_prefixed_value "$spotlight_pack_path" "- Fame readiness: ")"
fi
execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
if [[ -z "$execution_readiness" ]]; then
  execution_readiness="$(extract_prefixed_value "$spotlight_pack_path" "- Execution readiness: ")"
fi
primary_risk_call="$(extract_prefixed_value "$command_center_path" "- Primary risk call: ")"
if [[ -z "$primary_risk_call" ]]; then
  primary_risk_call="$(extract_prefixed_value "$spotlight_pack_path" "- Primary risk call: ")"
fi
routing_recommendation="$(extract_prefixed_value "$command_center_path" "- Routing recommendation: ")"
if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$(extract_prefixed_value "$spotlight_pack_path" "- Routing recommendation: ")"
fi
day_zero_ship_item="$(extract_prefixed_value "$spotlight_pack_path" "Today’s concrete move: ")"
narrative_route_winner="$(extract_prefixed_value "$command_center_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$command_center_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$command_center_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$command_center_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$command_center_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$command_center_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$command_center_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$command_center_path" "- Route mode: ")"
route_guardrail="$(extract_prefixed_value "$command_center_path" "Route guardrail: ")"
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$spotlight_pack_path" "- Route guardrail: ")"
fi
if [[ -z "$narrative_route_winner" ]]; then
  narrative_route_winner="$(extract_prefixed_value "$spotlight_pack_path" "- Narrative route winner: ")"
fi
if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="$(extract_prefixed_value "$spotlight_pack_path" "- Narrative route trend: ")"
fi
if [[ -z "$narrative_fame_velocity" ]]; then
  narrative_fame_velocity="$(extract_prefixed_value "$spotlight_pack_path" "- Narrative fame velocity: ")"
fi
if [[ -z "$narrative_ranked_opportunity" ]]; then
  narrative_ranked_opportunity="$(extract_prefixed_value "$spotlight_pack_path" "- Narrative-ranked opportunity: ")"
fi
if [[ -z "$execution_mode" ]]; then
  execution_mode="$(extract_prefixed_value "$spotlight_pack_path" "- Execution mode: ")"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$(extract_prefixed_value "$spotlight_pack_path" "- Route alignment signal: ")"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$(extract_prefixed_value "$spotlight_pack_path" "- Route lane status: ")"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$(extract_prefixed_value "$spotlight_pack_path" "- Route response mode: ")"
fi

execution_objective="$(extract_prefixed_value "$execution_sprint_path" "- Objective: ")"
day0_execution_objective="$(extract_table_cell_by_first_column "$execution_sprint_path" "## Day-by-Day Execution Grid" "Day 0" 2)"
day1_execution_objective="$(extract_table_cell_by_first_column "$execution_sprint_path" "## Day-by-Day Execution Grid" "Day 1" 2)"
day2_execution_objective="$(extract_table_cell_by_first_column "$execution_sprint_path" "## Day-by-Day Execution Grid" "Day 2" 2)"

distribution_mix_recommendation="$(extract_prefixed_value "$distribution_plan_path" "- Channel mix recommendation: ")"
day0_distribution_action="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 0" 3)"
day1_distribution_action="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 1" 3)"
day2_distribution_action="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 2" 3)"

hook_a_type="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Hook type: ")"
hook_a_seed="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Script seed: ")"
variant_recommendation="$(extract_section_prefixed_value "$winning_hook_library_path" "## Routing Notes" "- Variant recommendation: ")"
outreach_recommendation="$(extract_section_prefixed_value "$winning_hook_library_path" "## Routing Notes" "- Outreach recommendation: ")"

strongest_metric_signal="$(extract_prefixed_value "$credibility_ledger_path" "- Strongest metric: ")"
social_proof_leads="$(extract_prefixed_value "$credibility_ledger_path" "- Social proof leads: ")"
credibility_action_primary="$(extract_rg_match "$credibility_ledger_path" '^- \[ \] Publish one metric-backed proof post')"
credibility_action_backup="$(extract_rg_match "$credibility_ledger_path" '^- \[ \] Publish one credibility follow-up')"
credibility_action_primary="${credibility_action_primary#- [ ] }"
credibility_action_backup="${credibility_action_backup#- [ ] }"

top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "Narrative Compounding Loop")")"
fame_readiness="$(sanitize_inline "$(default_if_blank "$fame_readiness" "n/a")")"
execution_readiness="$(sanitize_inline "$(default_if_blank "$execution_readiness" "n/a")")"
primary_risk_call="$(sanitize_inline "$(default_if_blank "$primary_risk_call" "n/a")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one proof narrative until execution confidence is stable.")")"
day_zero_ship_item="$(sanitize_inline "$(default_if_blank "$day_zero_ship_item" "Ship one proof-first narrative asset with measurable outcome.")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "General narrative momentum mode")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "n/a")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$primary_risk_call")")"

execution_objective="$(sanitize_inline "$(default_if_blank "$execution_objective" "Execute one top-bet narrative loop with daily proof shipping.")")"
day0_execution_objective="$(sanitize_inline "$(default_if_blank "$day0_execution_objective" "Ship top-bet proof post in the lead channel.")")"
day1_execution_objective="$(sanitize_inline "$(default_if_blank "$day1_execution_objective" "Reinforce execution narrative on backup channel.")")"
day2_execution_objective="$(sanitize_inline "$(default_if_blank "$day2_execution_objective" "Convert objections into public proof with one docs-linked follow-up.")")"

distribution_mix_recommendation="$(sanitize_inline "$(default_if_blank "$distribution_mix_recommendation" "Keep channel mix balanced until distribution execution score is stable.")")"
day0_distribution_action="$(sanitize_inline "$(default_if_blank "$day0_distribution_action" "Publish proof-first post and log first 10 practical replies.")")"
day1_distribution_action="$(sanitize_inline "$(default_if_blank "$day1_distribution_action" "Ship backup-channel reinforcement and one creator follow-up burst.")")"
day2_distribution_action="$(sanitize_inline "$(default_if_blank "$day2_distribution_action" "Close top objections and publish one credibility follow-up.")")"

hook_a_type="$(sanitize_inline "$(default_if_blank "$hook_a_type" "Proof-First Outcome Hook")")"
hook_a_seed="$(sanitize_inline "$(default_if_blank "$hook_a_seed" "Share one measurable before/after and invite one practical follow-up.")")"
variant_recommendation="$(sanitize_inline "$(default_if_blank "$variant_recommendation" "Keep current top-performing variant as default and iterate one challenger.")")"
outreach_recommendation="$(sanitize_inline "$(default_if_blank "$outreach_recommendation" "Focus outreach on warm creator conversations and one follow-up pass.")")"
outreach_lane_strategy="$(resolve_outreach_lane_strategy "$social_proof_leads" "$outreach_recommendation")"
outreach_lane_strategy_label="$outreach_lane_strategy"
if [[ "$outreach_lane_strategy" == "creator-led" ]]; then
  outreach_lane_strategy_label="creator-led (creator-first outreach week)"
elif [[ "$outreach_lane_strategy" == "guesting-led" ]]; then
  outreach_lane_strategy_label="guesting-led (booking-first outreach week)"
else
  outreach_lane_strategy_label="balanced (creator + guesting parity week)"
fi

strongest_metric_signal="$(sanitize_inline "$(default_if_blank "$strongest_metric_signal" "n/a")")"
social_proof_leads="$(sanitize_inline "$(default_if_blank "$social_proof_leads" "creator n/a, founder target n/a")")"
credibility_action_primary="$(sanitize_inline "$(default_if_blank "$credibility_action_primary" "Publish one metric-backed proof post on the lead channel.")")"
credibility_action_backup="$(sanitize_inline "$(default_if_blank "$credibility_action_backup" "Publish one credibility follow-up on the backup channel.")")"

product_name="$(sanitize_inline "$product_name")"
primary_channel="$(sanitize_inline "$primary_channel")"
backup_channel="$(sanitize_inline "$backup_channel")"
cta_text="$(sanitize_inline "$cta_text")"
outreach_lane_strategy_label="$(sanitize_inline "$outreach_lane_strategy_label")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-breakout-plan -->

# Founder Fame Breakout Plan - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source spotlight pack: ${spotlight_pack_path}
Source command center: ${command_center_path:-n/a}
Source execution sprint: ${execution_sprint_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source winning hook library: ${winning_hook_library_path:-n/a}
Source credibility ledger: ${credibility_ledger_path:-n/a}

## Snapshot

- Spotlight pack: ${spotlight_heading}
- Command center: ${command_center_heading}
- Execution sprint: ${execution_sprint_heading}
- Distribution plan: ${distribution_heading}
- Winning hook library: ${winning_hook_heading}
- Credibility ledger: ${credibility_heading}
- Top bet: ${top_bet}
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Primary risk call: ${primary_risk_call}
- Routing recommendation: ${routing_recommendation}
- Breakout hook route: ${hook_a_type}
- Strongest proof signal: ${strongest_metric_signal}
- Outreach lane strategy: ${outreach_lane_strategy_label}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}

## Breakout Thesis

- Core narrative: ${top_bet}
- Weekly objective: ${execution_objective}
- Day 0 ship commitment: ${day_zero_ship_item}
- Channel mix decision: ${distribution_mix_recommendation}
- Risk guardrail: ${primary_risk_call}
- Script seed to lead with: ${hook_a_seed}

## Narrative Route Scale Plan

- Route winner: ${narrative_route_winner}
- Route trend: ${narrative_route_trend}
- Route alignment signal: ${route_alignment_signal}
- Route mode: ${execution_mode} (${route_response_mode})
- Route lane status: ${route_lane_status}
- Route priority opportunity: ${narrative_ranked_opportunity}
- Route guardrail: ${route_guardrail}
- Scale action: Keep ${narrative_ranked_opportunity} as the lead route until route lane status returns to Stable.

## 7-Day Fame Cadence

| Day | Objective | Channel lane | Primary move | Success signal |
| --- | --- | --- | --- | --- |
| Day 0 | ${day0_execution_objective} | ${primary_channel} | ${day0_distribution_action} | 1 high-intent reply asks for exact flow |
| Day 1 | ${day1_execution_objective} | ${backup_channel} | ${day1_distribution_action} | 1 warm intro or collaborator signal appears |
| Day 2 | ${day2_execution_objective} | Replies + comments | ${day2_distribution_action} | 2 objections closed with proof and docs |
| Day 3 | Amplify strongest hook with social proof | ${primary_channel} | Publish hook-driven follow-up + one measured update in ${execution_mode} | Engagement stays practical (questions > hype) |
| Day 4 | Convert creator signal into partnership burst | Creator + community DMs | Run one outreach burst using creator/founder proof lines | 1 partner conversation moves to next step |
| Day 5 | Reframe narrative with lessons learned | ${backup_channel} | Share operating lesson + next move | One audience segment asks for replication details |
| Day 6 | Lock next-week default narrative | Standup + issue comment | Promote winner hook + publish checklist update | Monday defaults are clear and owner-assigned |

## Channel Script Blocks

### Primary Channel Script (${primary_channel})

This week’s breakout move for ${product_name}: **${top_bet}**.

- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Ship now: ${day_zero_ship_item}
- Guardrail: ${primary_risk_call}

${cta_text}

### Backup Channel Script (${backup_channel})

Founder execution update:

- Bet: ${top_bet}
- Route: ${routing_recommendation}
- Hook lane: ${hook_a_type}
- Action: ${day1_distribution_action}

${cta_text}

### Fast Reply / Objection Script

- “Show me proof.” → “Strongest signal this week: ${strongest_metric_signal}. We’re shipping ${day_zero_ship_item} first.”
- “Why this angle?” → “Our route is ${routing_recommendation}; it keeps execution tight while we manage ${primary_risk_call}.”
- “What should I do first?” → “Start with ${hook_a_seed} and follow with one backup-channel reinforcement within 24 hours.”

## Partnership Bursts

- Creator burst lane: ${social_proof_leads}
- Outreach lane strategy: ${outreach_lane_strategy_label}
- Outreach recommendation: ${outreach_recommendation}
- Variant recommendation: ${variant_recommendation}
- Burst action 1: Turn one practical reply into a creator collaboration ask.
- Burst action 2: Turn one founder guesting signal into a booking-ready pitch.
- Burst action 3: Capture one quote + one objection and route into next spotlight revision.

## Fame Flywheel Metrics

| Loop | Current signal | This-week target |
| --- | --- | --- |
| Narrative clarity | Top bet: ${top_bet} | Keep one narrative across all public posts |
| Route integrity | ${narrative_route_winner} / ${route_alignment_signal} | Keep route lane status Stable with no mode drift |
| Proof velocity | Strongest metric: ${strongest_metric_signal} | Publish 2 proof-backed posts with measurable outcomes |
| Response quality | Risk + routing: ${primary_risk_call} / ${routing_recommendation} | Close 3 objections with proof + docs links |
| Distribution discipline | Channel mix: ${distribution_mix_recommendation} | Execute Day 0-Day 2 actions with no missed handoffs |
| Partner leverage | Social proof leads: ${social_proof_leads} | Trigger 2 creator/guesting conversations this week |

## Daily Standup Prompts

1. Is **${top_bet}** still the highest-leverage narrative for today?
2. Did yesterday’s post produce practical replies, not vanity engagement?
3. Which objection repeated most, and which proof line resolves it fastest?
4. Which partner signal should move today (creator or guesting)?
5. What must ship before we expand into additional channels?

## Execution Checklist

- [ ] Ship Day 0 proof-first post with one measurable claim.
- [ ] Publish backup-channel reinforcement inside 24 hours.
- [ ] Run one creator + one guesting burst action.
- [ ] Apply ${hook_a_type} as today’s default opener.
- [ ] Run credibility action: ${credibility_action_primary}
- [ ] Run credibility action: ${credibility_action_backup}
- [ ] Refresh spotlight + breakout plan after major reply wave.
EOF

echo "Generated founder fame breakout plan: $output_path"
