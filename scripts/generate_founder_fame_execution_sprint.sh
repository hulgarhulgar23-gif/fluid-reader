#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame execution sprint from the opportunity radar and weekly launch artifacts.

Usage:
  zsh scripts/generate_founder_fame_execution_sprint.sh [options]

Required:
  --opportunity-radar <path>      Founder fame opportunity radar markdown

Optional:
  --momentum-brief <path>         Founder fame momentum brief markdown
  --distribution-plan <path>      7-day distribution follow-up plan markdown
  --monday-checkpoint <path>      Monday publish checkpoint markdown
  --reply-pack <path>             First-24-hour reply pack markdown
  --week <label>                  Week label (default: inferred from opportunity radar, then current ISO week)
  --product <text>                Product name (default: Fluid Reader)
  --out <path>                    Output path (default: docs/campaigns/<week>-founder-fame-execution-sprint.md)
  -h, --help                      Show help

Example:
  zsh scripts/generate_founder_fame_execution_sprint.sh \
    --opportunity-radar docs/campaigns/2026-W24-founder-fame-opportunity-radar.md \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --monday-checkpoint docs/campaigns/2026-W24-monday-checkpoint.md \
    --reply-pack docs/campaigns/2026-W24-reply-pack.md \
    --out docs/campaigns/2026-W24-founder-fame-execution-sprint.md
EOF
}

opportunity_radar_path=""
momentum_brief_path=""
distribution_plan_path=""
monday_checkpoint_path=""
reply_pack_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --opportunity-radar)
      opportunity_radar_path="${2:-}"
      shift 2
      ;;
    --momentum-brief)
      momentum_brief_path="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
      shift 2
      ;;
    --monday-checkpoint)
      monday_checkpoint_path="${2:-}"
      shift 2
      ;;
    --reply-pack)
      reply_pack_path="${2:-}"
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

if [[ -z "$opportunity_radar_path" ]]; then
  echo "Missing required option: --opportunity-radar" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$opportunity_radar_path" ]]; then
  echo "Opportunity radar file not found: $opportunity_radar_path" >&2
  exit 1
fi

for optional_path in "$momentum_brief_path" "$distribution_plan_path" "$monday_checkpoint_path" "$reply_pack_path"; do
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
  value="$(trim_value "$value")"
  echo "$value"
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

extract_week_from_radar_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Opportunity Radar - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Opportunity Radar - "}"
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

extract_table_row_value() {
  local source_path="$1"
  local section_heading="$2"
  local row_index="$3"
  local column_index="$4"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="$section_heading" -v target="$row_index" -v column="$column_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Rank" || first == "Day" || first ~ /^---/) next
      count++
      if (count == target) {
        idx = column + 1
        value = clean($(idx))
        print value
        exit
      }
    }
  ' "$source_path"
}

extract_day_plan_value() {
  local source_path="$1"
  local day_label="$2"
  local column_index="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="## Day-by-Day Distribution Plan" -v day="$day_label" -v column="$column_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Day" || first ~ /^---/) next
      if (first == day) {
        idx = column + 1
        value = clean($(idx))
        print value
        exit
      }
    }
  ' "$source_path"
}

extract_reply_prompt() {
  local source_path="$1"
  local prompt_index="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -v target="$prompt_index" '
    /^## Core Replies/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^### Reply:/ {
      count++
      if (count == target) {
        line = $0
        sub(/^### Reply:[[:space:]]*/, "", line)
        gsub(/^"|"$/, "", line)
        print line
        exit
      }
    }
  ' "$source_path"
}

extract_checklist_line() {
  local source_path="$1"
  local section_heading="$2"
  local index="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -v heading="$section_heading" -v target="$index" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^- \[ \]/ {
      count++
      if (count == target) {
        sub(/^- \[ \][[:space:]]*/, "", $0)
        print $0
        exit
      }
    }
  ' "$source_path"
}

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

normalize_narrative_route() {
  local value lowered
  value="$(trim_value "$1")"
  lowered="${value:l}"
  if [[ -z "$value" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"proof-first"* || "$lowered" == *"proof first"* ]]; then
    echo "Proof-first route"
    return
  fi
  if [[ "$lowered" == *"behind-the-scenes"* || "$lowered" == *"behind the scenes"* || "$lowered" == *"bts"* ]]; then
    echo "Behind-the-scenes route"
    return
  fi
  if [[ "$lowered" == *"objection-breaker"* || "$lowered" == *"objection breaker"* || "$lowered" == *"objection-handler"* || "$lowered" == *"objection handler"* ]]; then
    echo "Objection-breaker route"
    return
  fi
  if [[ "$lowered" == *"hook-driven"* || "$lowered" == *"hook driven"* ]]; then
    echo "Hook-driven overlay"
    return
  fi
  echo "$value"
}

normalize_opportunity_name() {
  local value lowered
  value="$(trim_value "$1")"
  value="${value%%\(*}"
  value="$(trim_value "$value")"
  lowered="${value:l}"
  if [[ -z "$value" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"distribution recovery sprint"* ]]; then
    echo "Distribution Recovery Sprint"
    return
  fi
  if [[ "$lowered" == *"objection crush sequence"* ]]; then
    echo "Objection Crush Sequence"
    return
  fi
  if [[ "$lowered" == *"kpi proof amplifier"* ]]; then
    echo "KPI Proof Amplifier"
    return
  fi
  if [[ "$lowered" == *"narrative compounding loop"* ]]; then
    echo "Narrative Compounding Loop"
    return
  fi
  echo "$value"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_radar_heading "$opportunity_radar_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-execution-sprint.md"
fi

radar_heading="$(extract_heading "$opportunity_radar_path")"
momentum_heading="$(extract_heading "$momentum_brief_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
monday_heading="$(extract_heading "$monday_checkpoint_path")"
reply_heading="$(extract_heading "$reply_pack_path")"

top_bet="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Bet: ")"
top_priority_raw="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Priority score: ")"
top_owner="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Owner: ")"
top_first_move="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Ship in first 24 hours: ")"
lead_script_seed="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Lead script seed: ")"
hook_seed="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Hook seed: ")"
why_now="$(extract_section_prefixed_value "$opportunity_radar_path" "## Weekly Fame Bet" "- Why now: ")"
top_guardrail="$(extract_prefixed_value "$opportunity_radar_path" "- Guardrail: ")"
narrative_route_winner_raw="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative route trend: ")"
narrative_fame_velocity_score="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative fame velocity score: ")"
narrative_route_recommendation="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative recommendation: ")"
narrative_ranked_opportunity_raw="$(extract_prefixed_value "$opportunity_radar_path" "- Narrative-ranked opportunity: ")"

backup_bet="$(extract_table_row_value "$opportunity_radar_path" "## Ranked Opportunities" 2 2)"
backup_priority_raw="$(extract_table_row_value "$opportunity_radar_path" "## Ranked Opportunities" 2 6)"
backup_owner="$(extract_table_row_value "$opportunity_radar_path" "## Ranked Opportunities" 2 7)"

readiness_line="$(extract_prefixed_value "$momentum_brief_path" "- Fame readiness score: ")"
weakest_signal_line="$(extract_prefixed_value "$momentum_brief_path" "- Weakest signal now: ")"
primary_risk_line="$(extract_prefixed_value "$momentum_brief_path" "- Primary risk call: ")"

day0_objective="$(extract_day_plan_value "$distribution_plan_path" "Day 0" 2)"
day0_success="$(extract_day_plan_value "$distribution_plan_path" "Day 0" 6)"
day2_objective="$(extract_day_plan_value "$distribution_plan_path" "Day 2" 2)"
day2_success="$(extract_day_plan_value "$distribution_plan_path" "Day 2" 6)"
day5_objective="$(extract_day_plan_value "$distribution_plan_path" "Day 5" 2)"
day5_success="$(extract_day_plan_value "$distribution_plan_path" "Day 5" 6)"

primary_window_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Primary channel ")"
backup_window_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Backup channel ")"
fallback_window_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Fallback publish window: ")"
sequence_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Recommended sequence: ")"

reply_prompt_1="$(extract_reply_prompt "$reply_pack_path" 1)"
reply_prompt_2="$(extract_reply_prompt "$reply_pack_path" 2)"
reply_checklist_1="$(extract_checklist_line "$reply_pack_path" "## First 24-Hour Execution Checklist" 1)"
distribution_checklist_1="$(extract_checklist_line "$distribution_plan_path" "## Execution Checklist" 1)"

if [[ -z "$top_bet" ]]; then
  top_bet="Narrative Compounding Loop"
fi

narrative_route_winner="$(normalize_narrative_route "$narrative_route_winner_raw")"
narrative_ranked_opportunity="$(normalize_opportunity_name "$narrative_ranked_opportunity_raw")"

top_priority_number="$(extract_number "$top_priority_raw")"
if [[ -z "$top_priority_number" ]]; then
  top_priority_number="60"
fi

backup_priority_number="$(extract_number "$backup_priority_raw")"
if [[ -z "$backup_priority_number" ]]; then
  backup_priority_number="55"
fi

if [[ -z "$top_owner" ]]; then
  top_owner="Founder growth lead"
fi

if [[ -z "$top_first_move" ]]; then
  top_first_move="Publish one proof-led founder post in the next launch window."
fi

if [[ -z "$lead_script_seed" ]]; then
  lead_script_seed="Founder story hook + one practical command walkthrough."
fi

if [[ -z "$hook_seed" ]]; then
  hook_seed="One measurable outcome + one repeatable workflow."
fi

if [[ -z "$why_now" ]]; then
  why_now="Momentum is compounding and this bet has the highest near-term leverage."
fi

if [[ -z "$top_guardrail" ]]; then
  top_guardrail="Keep distribution and reply loops tight while shipping founder proof daily."
fi

if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="n/a"
fi

if [[ -z "$narrative_fame_velocity_score" ]]; then
  narrative_fame_velocity_score="n/a"
fi

if [[ -z "$narrative_route_recommendation" ]]; then
  narrative_route_recommendation="Capture founder fame narrative lab comment before Friday review to track route winners."
fi

if [[ -z "$narrative_ranked_opportunity" || "$narrative_ranked_opportunity" == "n/a" ]]; then
  narrative_ranked_opportunity="$top_bet"
fi

if [[ -z "$backup_bet" ]]; then
  backup_bet="Distribution Recovery Sprint"
fi

if [[ -z "$backup_owner" ]]; then
  backup_owner="$top_owner"
fi

if [[ -z "$readiness_line" ]]; then
  readiness_line="n/a"
fi

if [[ -z "$weakest_signal_line" ]]; then
  weakest_signal_line="n/a"
fi

if [[ -z "$primary_risk_line" ]]; then
  primary_risk_line="n/a"
fi

if [[ -z "$day0_objective" ]]; then
  day0_objective="Ship top-bet founder post + first 3 practical replies."
fi

if [[ -z "$day0_success" ]]; then
  day0_success="Top-bet asset published and first practical replies completed."
fi

if [[ -z "$day2_objective" ]]; then
  day2_objective="Run creator/community follow-up wave."
fi

if [[ -z "$day2_success" ]]; then
  day2_success="At least two meaningful conversations opened."
fi

if [[ -z "$day5_objective" ]]; then
  day5_objective="Convert strongest objection into docs/workflow proof."
fi

if [[ -z "$day5_success" ]]; then
  day5_success="One reusable docs/workflow update shipped."
fi

if [[ -z "$primary_window_line" ]]; then
  primary_window_line="n/a"
fi

if [[ -z "$backup_window_line" ]]; then
  backup_window_line="n/a"
fi

if [[ -z "$fallback_window_line" ]]; then
  fallback_window_line="n/a"
fi

if [[ -z "$sequence_line" ]]; then
  sequence_line="Lead with top-bet post, then reinforce in backup channel window."
fi

if [[ -z "$reply_prompt_1" ]]; then
  reply_prompt_1="How do I start?"
fi

if [[ -z "$reply_prompt_2" ]]; then
  reply_prompt_2="What is the real benefit?"
fi

if [[ -z "$reply_checklist_1" ]]; then
  reply_checklist_1="Reply to practical setup questions within 24 hours."
fi

if [[ -z "$distribution_checklist_1" ]]; then
  distribution_checklist_1="Lead-channel post shipped in planned window."
fi

execution_mode="General narrative momentum mode"
execution_guardrail="$top_guardrail"
day1_mission="Reinforce launch narrative across backup channel window"
day1_asset="$lead_script_seed"
day1_success="Cross-channel reinforcement shipped using sequence: $sequence_line"
day1_owner="Founder + distribution lead"
day2_mission="$day2_objective"
day2_asset="Reply prompt focus: \"$reply_prompt_1\""
day2_owner="Community + partnerships"
day3_mission="Run objection-crush loop and tighten proof language"
day3_asset="Reply prompt focus: \"$reply_prompt_2\""
day3_success="One repeated objection converted into reusable proof response"
day3_owner="Founder + support lead"
checkin_prompt_2="Which channel delivered the most practical conversations today?"
checkin_prompt_3="Which reply pattern drove the strongest conversion intent?"
checkin_prompt_4="Which objection repeated enough to require a docs/workflow update?"
escalation_trigger_1="If Day 0 ship slips more than 24 hours, pause backup bets and ship only the top-bet narrative loop."
escalation_trigger_2="If Day 2 conversations stay below target, add one extra creator/community wave before Day 3."
escalation_trigger_3="If repeated objections appear 3+ times, ship one docs/workflow patch within 24 hours."
escalation_trigger_4="If distribution execution drifts by Day 5, switch Day 6 to proof recap + partner outreach only."

case "$narrative_route_winner" in
  "Proof-first route")
    execution_mode="Proof-first acceleration mode"
    execution_guardrail="Keep every public touchpoint anchored in measurable proof + one practical command sequence."
    day1_mission="Scale proof-first narrative across backup channel window"
    day1_asset="Proof stack replay: $lead_script_seed"
    day1_success="Primary + backup proof stories shipped with explicit command flow."
    day2_asset="Reply prompt focus: \"$reply_prompt_1\" + one concrete before/after proof."
    day3_mission="Run proof-to-objection conversion loop"
    day3_asset="Reply prompt focus: \"$reply_prompt_2\" + objection-proof bridge line"
    day3_success="One repeated objection converted into a proof-backed reusable reply and docs patch candidate."
    checkin_prompt_2="Did today’s proof artifact answer the top practical setup question?"
    checkin_prompt_3="Which proof point generated the strongest conversion intent?"
    checkin_prompt_4="Which objection now needs a proof-backed docs/workflow patch?"
    escalation_trigger_1="If Day 0 proof asset slips more than 12 hours, cancel backup experiments and ship proof-first in the next available window."
    escalation_trigger_2="If proof replies do not improve by Day 2, add one extra proof artifact and re-run outreach with proof-first framing."
    ;;
  "Behind-the-scenes route")
    execution_mode="Behind-the-scenes compounding mode"
    execution_guardrail="Ship one transparent founder build-log moment daily and tie it to one user-facing outcome."
    day1_mission="Publish founder build-log continuation in backup channel window"
    day1_asset="Build-log seed: $lead_script_seed"
    day1_success="Two channels show consistent behind-the-scenes narrative continuity."
    day2_asset="Reply prompt focus: \"$reply_prompt_1\" + one process screenshot or log excerpt."
    day3_mission="Convert behind-the-scenes friction into practical lessons"
    day3_asset="Reply prompt focus: \"$reply_prompt_2\" + what changed in workflow today"
    day3_success="One build-log lesson converted into a reusable operator note."
    checkin_prompt_2="Which build-log detail drove the most practical conversations today?"
    checkin_prompt_3="Which audience response confirms behind-the-scenes trust is compounding?"
    checkin_prompt_4="Which workflow change should become tomorrow’s build-log highlight?"
    escalation_trigger_2="If behind-the-scenes engagement stalls by Day 2, add one explicit before/after outcome to the next post."
    ;;
  "Objection-breaker route")
    execution_mode="Objection-breaker conversion mode"
    execution_guardrail="Prioritize repeated objections and convert each into one proof-backed response asset within 24 hours."
    day1_mission="Lead with objection-breaker framing in backup channel window"
    day1_asset="Objection script seed: $lead_script_seed"
    day1_success="Top objection published with proof-backed response in both channels."
    day2_asset="Reply prompt focus: \"$reply_prompt_1\" + objection triage tracker update."
    day3_mission="Close objection loop and publish one docs/workflow patch candidate"
    day3_asset="Reply prompt focus: \"$reply_prompt_2\" + objection-to-proof template"
    day3_success="At least one repeated objection resolved with a reusable response + docs action."
    checkin_prompt_2="Which objection generated the most resistance today?"
    checkin_prompt_3="Which objection-breaker response drove conversion momentum?"
    checkin_prompt_4="Which unresolved objection must be patched in docs/workflow by tomorrow?"
    escalation_trigger_2="If unresolved objections remain above target by Day 2, run a dedicated objection-breaker wave before new outreach."
    escalation_trigger_3="If the same objection repeats 4+ times, ship one docs/workflow patch within 12 hours."
    ;;
  "Hook-driven overlay")
    execution_mode="Hook-driven experimentation mode"
    execution_guardrail="Run one controlled hook experiment daily while preserving proof quality and response speed."
    day1_mission="Ship hook remix in backup channel while preserving core proof narrative"
    day1_asset="Hook test seed: $hook_seed"
    day1_success="Hook variant performance logged with clear winner/loser notes."
    day2_asset="Reply prompt focus: \"$reply_prompt_1\" + hook feedback capture."
    day3_mission="Select winning hook and pair it with strongest proof response"
    day3_asset="Reply prompt focus: \"$reply_prompt_2\" + winning hook overlay"
    day3_success="One hook winner selected and promoted into next-day defaults."
    checkin_prompt_2="Which hook variant created the most qualified conversation starts?"
    checkin_prompt_3="Which hook + proof combination drove the best response quality?"
    checkin_prompt_4="Which hook failed and should be removed from tomorrow’s queue?"
    escalation_trigger_2="If hook tests do not produce a clear winner by Day 2, pause experiments and revert to best-known proof-first opener."
    ;;
esac

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- founder-fame-execution-sprint -->

# Founder Fame Execution Sprint - $week_label

Generated: $generated_on
Product: $product_name
Source opportunity radar: $opportunity_radar_path
Source momentum brief: ${momentum_brief_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source Monday checkpoint: ${monday_checkpoint_path:-n/a}
Source reply pack: ${reply_pack_path:-n/a}

## Snapshot

- Opportunity radar: $radar_heading
- Momentum brief: $momentum_heading
- Distribution plan: $distribution_heading
- Monday checkpoint: $monday_heading
- Reply pack: $reply_heading
- Top bet this week: $top_bet
- Top bet priority: ${top_priority_number}/100
- Suggested owner: $top_owner
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity score: ${narrative_fame_velocity_score}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Fame readiness context: $readiness_line
- Weakest signal context: $weakest_signal_line
- Primary risk call: $primary_risk_line

## Weekly Fame Objective

- Objective: Execute $top_bet as the anchor fame narrative this week.
- Day 0 ship item: $(sanitize_inline "$top_first_move")
- Lead script seed: $(sanitize_inline "$lead_script_seed")
- Hook seed: $(sanitize_inline "$hook_seed")
- Why this week: $(sanitize_inline "$why_now")
- Guardrail: $(sanitize_inline "$top_guardrail")
- Backup bet by Day 4: $(sanitize_inline "$backup_bet") (${backup_priority_number}/100, owner: $(sanitize_inline "$backup_owner"))

## Narrative Route Execution Mode

- Narrative route winner: $(sanitize_inline "$narrative_route_winner")
- Route trend: $(sanitize_inline "$narrative_route_trend")
- Fame velocity score: $(sanitize_inline "$narrative_fame_velocity_score")
- Ranked route opportunity: $(sanitize_inline "$narrative_ranked_opportunity")
- Execution mode: $(sanitize_inline "$execution_mode")
- Route recommendation: $(sanitize_inline "$narrative_route_recommendation")
- Route-specific guardrail: $(sanitize_inline "$execution_guardrail")

## 7-Day Mission Board

| Day | Mission | Asset / Script | Success signal | Owner |
| --- | --- | --- | --- | --- |
| Day 0 | $(sanitize_inline "$day0_objective") | $(sanitize_inline "$top_first_move") | $(sanitize_inline "$day0_success") | $(sanitize_inline "$top_owner") |
| Day 1 | $(sanitize_inline "$day1_mission") | $(sanitize_inline "$day1_asset") | $(sanitize_inline "$day1_success") | $(sanitize_inline "$day1_owner") |
| Day 2 | $(sanitize_inline "$day2_mission") | $(sanitize_inline "$day2_asset") | $(sanitize_inline "$day2_success") | $(sanitize_inline "$day2_owner") |
| Day 3 | $(sanitize_inline "$day3_mission") | $(sanitize_inline "$day3_asset") | $(sanitize_inline "$day3_success") | $(sanitize_inline "$day3_owner") |
| Day 4 | Probe backup bet in one public asset | Backup bet: $(sanitize_inline "$backup_bet") with hook "$(sanitize_inline "$hook_seed")" | Backup bet shipped and compared against top-bet response quality | $(sanitize_inline "$backup_owner") |
| Day 5 | $(sanitize_inline "$day5_objective") | Checklist anchor: $(sanitize_inline "$distribution_checklist_1") | $(sanitize_inline "$day5_success") | Product + docs owner |
| Day 6 | Publish recap and lock next-week handoff | Recap from top bet + one next-week ask | Friday handoff includes next-week hook seed + owner assignment | Founder growth lead |

## Daily Check-In Prompts

1. Did Day 0 top-bet ship in the planned window?
2. $(sanitize_inline "$checkin_prompt_2")
3. $(sanitize_inline "$checkin_prompt_3")
4. $(sanitize_inline "$checkin_prompt_4")
5. What should we cut tomorrow to keep focus on the top bet?

## Escalation Triggers

- $(sanitize_inline "$escalation_trigger_1")
- $(sanitize_inline "$escalation_trigger_2")
- $(sanitize_inline "$escalation_trigger_3")
- $(sanitize_inline "$escalation_trigger_4")

## Share Block

\`\`\`text
Founder fame execution sprint ($week_label)
Top bet: $top_bet (${top_priority_number}/100)
Narrative route: $(sanitize_inline "$narrative_route_winner")
Execution mode: $(sanitize_inline "$execution_mode")
Owner: $top_owner
Day 0 ship item: $(sanitize_inline "$top_first_move")
Primary window: $(sanitize_inline "$primary_window_line")
Backup window: $(sanitize_inline "$backup_window_line")
Fallback window: $(sanitize_inline "$fallback_window_line")
Guardrail: $(sanitize_inline "$top_guardrail")
Route guardrail: $(sanitize_inline "$execution_guardrail")
Reply SLA: $(sanitize_inline "$reply_checklist_1")
\`\`\`
EOF

echo "Generated founder fame execution sprint: $output_path"
