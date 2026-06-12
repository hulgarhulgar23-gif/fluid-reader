#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame spotlight pack from command-center and execution artifacts.

Usage:
  zsh scripts/generate_founder_fame_spotlight_pack.sh [options]

Required:
  --command-center <path>       Founder fame command center markdown

Optional:
  --momentum-brief <path>       Founder fame momentum brief markdown
  --execution-scorecard <path>  Founder fame execution scorecard markdown
  --risk-response-plan <path>   Founder fame risk response plan markdown
  --week <label>                Week label (default: inferred from command center heading, then current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --primary-channel <text>      Primary publishing channel (default: X / Threads)
  --backup-channel <text>       Backup publishing channel (default: LinkedIn)
  --cta <text>                  CTA line for public drafts
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-spotlight-pack.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_spotlight_pack.sh \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --execution-scorecard docs/campaigns/2026-W24-founder-fame-execution-scorecard.md \
    --risk-response-plan docs/campaigns/2026-W24-founder-fame-risk-response-plan.md \
    --out docs/campaigns/2026-W24-founder-fame-spotlight-pack.md
EOF
}

command_center_path=""
momentum_brief_path=""
execution_scorecard_path=""
risk_response_plan_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="Reply with your KPI bottleneck and I will share the exact command stack."
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --momentum-brief)
      momentum_brief_path="${2:-}"
      shift 2
      ;;
    --execution-scorecard)
      execution_scorecard_path="${2:-}"
      shift 2
      ;;
    --risk-response-plan)
      risk_response_plan_path="${2:-}"
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

if [[ -z "$command_center_path" ]]; then
  echo "Missing required option: --command-center" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$command_center_path" ]]; then
  echo "Required source file not found: $command_center_path" >&2
  exit 1
fi

for optional_path in "$momentum_brief_path" "$execution_scorecard_path" "$risk_response_plan_path"; do
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

default_if_blank() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$command_center_path" "# Founder Fame Command Center - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-spotlight-pack.md"
fi

mkdir -p "$(dirname "$output_path")"

command_center_heading="$(extract_heading "$command_center_path")"
momentum_heading="$(extract_heading "$momentum_brief_path")"
execution_heading="$(extract_heading "$execution_scorecard_path")"
risk_heading="$(extract_heading "$risk_response_plan_path")"

top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
fame_readiness="$(extract_prefixed_value "$command_center_path" "- Fame readiness: ")"
execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
queue_pressure="$(extract_prefixed_value "$command_center_path" "- Queue pressure: ")"
response_urgency="$(extract_prefixed_value "$command_center_path" "- Response urgency: ")"
primary_risk_call="$(extract_prefixed_value "$command_center_path" "- Primary risk call: ")"
routing_recommendation="$(extract_prefixed_value "$command_center_path" "- Routing recommendation: ")"
narrative_route_winner="$(extract_prefixed_value "$command_center_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$command_center_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$command_center_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$command_center_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$command_center_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$command_center_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$command_center_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$command_center_path" "- Route mode: ")"
route_guardrail="$(extract_prefixed_value "$command_center_path" "Route guardrail: ")"
day_zero_ship_item="$(extract_prefixed_value "$command_center_path" "Day 0 ship item: ")"
standup_top_bet="$(extract_prefixed_value "$command_center_path" "Top bet: ")"
standup_primary_risk="$(extract_prefixed_value "$command_center_path" "Primary risk: ")"
standup_routing_call="$(extract_prefixed_value "$command_center_path" "Routing call: ")"
standup_route_signal="$(extract_prefixed_value "$command_center_path" "Route signal: ")"
standup_route_lane="$(extract_prefixed_value "$command_center_path" "Route lane: ")"
weakest_signal="$(extract_prefixed_value "$momentum_brief_path" "- Weakest signal now: ")"
response_mode="$(extract_prefixed_value "$risk_response_plan_path" "- Response mode: ")"
response_priority_risk="$(extract_prefixed_value "$risk_response_plan_path" "- Primary risk call: ")"

if [[ -z "$top_bet" ]]; then
  top_bet="$standup_top_bet"
fi
if [[ -z "$primary_risk_call" ]]; then
  primary_risk_call="$standup_primary_risk"
fi
if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$standup_routing_call"
fi
if [[ -z "$primary_risk_call" ]]; then
  primary_risk_call="$response_priority_risk"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$(extract_prefixed_value "$risk_response_plan_path" "- Route response mode: ")"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$risk_response_plan_path" "- Route-specific guardrail: ")"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$primary_risk_call"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$standup_route_signal"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$standup_route_lane"
fi

top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "n/a")")"
fame_readiness="$(sanitize_inline "$(default_if_blank "$fame_readiness" "n/a")")"
execution_readiness="$(sanitize_inline "$(default_if_blank "$execution_readiness" "n/a")")"
queue_pressure="$(sanitize_inline "$(default_if_blank "$queue_pressure" "n/a")")"
response_urgency="$(sanitize_inline "$(default_if_blank "$response_urgency" "n/a")")"
primary_risk_call="$(sanitize_inline "$(default_if_blank "$primary_risk_call" "n/a")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one proof narrative until execution confidence improves.")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "General narrative momentum mode")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "n/a")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$primary_risk_call")")"
day_zero_ship_item="$(sanitize_inline "$(default_if_blank "$day_zero_ship_item" "Ship one proof artifact tied to the top bet.")")"
weakest_signal="$(sanitize_inline "$(default_if_blank "$weakest_signal" "n/a")")"
response_mode="$(sanitize_inline "$(default_if_blank "$response_mode" "n/a")")"
primary_channel="$(sanitize_inline "$primary_channel")"
backup_channel="$(sanitize_inline "$backup_channel")"
product_name="$(sanitize_inline "$product_name")"
cta_text="$(sanitize_inline "$cta_text")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-spotlight-pack -->

# Founder Fame Spotlight Pack - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source command center: ${command_center_path}
Source momentum brief: ${momentum_brief_path:-n/a}
Source execution scorecard: ${execution_scorecard_path:-n/a}
Source risk response plan: ${risk_response_plan_path:-n/a}

## Snapshot

- Command center: ${command_center_heading}
- Momentum brief: ${momentum_heading}
- Execution scorecard: ${execution_heading}
- Risk response plan: ${risk_heading}
- Top bet: ${top_bet}
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Queue pressure: ${queue_pressure}
- Response urgency: ${response_urgency}
- Primary risk call: ${primary_risk_call}
- Weakest signal now: ${weakest_signal}
- Response mode: ${response_mode}
- Routing recommendation: ${routing_recommendation}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}
- Route response mode: ${route_response_mode}

## Daily Spotlight Sequence

| Day | Objective | Channel | Script angle | Success check |
| --- | --- | --- | --- | --- |
| Day 0 | Ship the highest-confidence proof from the top bet | ${primary_channel} | Proof-first opener anchored to one measurable win | One high-intent reply asking for workflow details |
| Day 1 | Expand trust with execution evidence | ${backup_channel} | Behind-the-scenes execution update from the command center | One warm intro or collaboration lead |
| Day 2 | Convert objections into social proof | Community comments + replies | Objection-to-proof response using risk + mitigation language | Two objections closed with concrete proof |

## Copy-Ready Posts

### Primary Channel Draft (${primary_channel})

Building ${product_name}: this week’s top bet is **${top_bet}**.

Current signal stack:
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Queue pressure: ${queue_pressure}

We’re shipping: ${day_zero_ship_item}
Risk we are managing in public: ${primary_risk_call}

${cta_text}

### Backup Channel Draft (${backup_channel})

Weekly founder spotlight:
- Focus: ${top_bet}
- Readiness: ${execution_readiness}
- Risk mode: ${response_mode}

Execution reality:
- Weakest signal: ${weakest_signal}
- Risk call: ${primary_risk_call}
- Routing: ${routing_recommendation}

Today’s concrete move: ${day_zero_ship_item}
${cta_text}

### Community Reply Ladder

1. **Interest reply:** “Happy to share the exact sequence we used for ${top_bet}. Want the 3-step version or full checklist?”
2. **Skeptic reply:** “Fair pushback. Our highest current risk is ${primary_risk_call}; we are mitigating it by shipping ${day_zero_ship_item} first.”
3. **Ready-to-try reply:** “Start with one proof artifact, then post the follow-up in ${backup_channel}. If you want, I can share our exact day-by-day sequence.”

## Route Integrity Messaging

- Route winner call: ${narrative_route_winner} (${narrative_route_trend})
- Route mode call: ${execution_mode} with lane status ${route_lane_status}
- Route alignment call: ${route_alignment_signal}
- Route guardrail: ${route_guardrail}
- Route action line: “We are keeping ${narrative_ranked_opportunity} as the active narrative lane until alignment improves.”

## Live Objection Replies

- **“This feels too early to share publicly.”**
  “Agreed on the risk. Our current response urgency is ${response_urgency}, so we are sharing one constrained proof item first: ${day_zero_ship_item}.”
- **“What if momentum drops after the first post?”**
  “We track queue pressure (${queue_pressure}) and reroute with one narrative if drift appears. We avoid adding new lanes until proof converts.”
- **“How do you prioritize next actions?”**
  “We rank by top bet (${top_bet}) and route every action through one readiness + one risk signal before publishing.”

## Media / Partner Pitches

- **Podcast opener:** “This week we are executing ${top_bet} with an explicit risk protocol (${primary_risk_call}) and daily proof shipping.”
- **Newsletter blurb:** “Founder spotlight: ${product_name} is running a public execution sprint around ${top_bet}, with readiness at ${execution_readiness} and clear mitigation cadence.”
- **Partner DM:** “We’re sharing a transparent founder execution playbook this week: top bet, risk response, and daily proof artifacts. Want early access to the checklist?”

## Standup-to-Public Bridge

- Internal standup source: ${command_center_heading}
- Public narrative anchor: ${top_bet}
- Public guardrail: ${primary_risk_call}
- Public routing call: ${routing_recommendation}
- Public route signal: ${route_alignment_signal}
- Public route mode: ${route_response_mode}
- Day 0 ship commitment: ${day_zero_ship_item}

## Execution Checklist

- [ ] Publish primary draft with one measurable proof.
- [ ] Post backup draft with execution context.
- [ ] Resolve two public objections using proof + mitigation language.
- [ ] Send one podcast pitch and one partner DM.
- [ ] Log reply outcomes before next standup.
EOF

echo "Generated founder fame spotlight pack: $output_path"
