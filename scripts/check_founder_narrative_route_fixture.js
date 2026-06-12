#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Extract previous Monday checklist effectiveness';
const narrativeMarker = '<!-- weekly-growth-founder-fame-narrative-lab -->';

function leadingSpaces(value) {
  const match = String(value || '').match(/^(\s*)/);
  return match ? match[1].length : 0;
}

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function extractStepScript(filePath, targetStepName) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const stepLineIndex = lines.findIndex((line) => line.includes(`- name: ${targetStepName}`));
  assertCondition(stepLineIndex >= 0, `Could not find workflow step: ${targetStepName}`);

  let scriptLineIndex = -1;
  for (let index = stepLineIndex + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (index > stepLineIndex + 1 && /^\s*-\s+name:/.test(line)) {
      break;
    }
    if (/^\s*script:\s*\|\s*$/.test(line)) {
      scriptLineIndex = index;
      break;
    }
  }

  assertCondition(scriptLineIndex >= 0, `Could not find script block for step: ${targetStepName}`);

  const scriptIndent = leadingSpaces(lines[scriptLineIndex]);
  const blockLines = [];
  for (let index = scriptLineIndex + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === '') {
      blockLines.push('');
      continue;
    }
    const indent = leadingSpaces(line);
    if (indent <= scriptIndent) {
      break;
    }
    blockLines.push(line);
  }

  const nonEmptyLines = blockLines.filter((line) => line.trim() !== '');
  assertCondition(nonEmptyLines.length > 0, `Workflow step script is empty: ${targetStepName}`);
  const minimumIndent = Math.min(...nonEmptyLines.map((line) => leadingSpaces(line)));
  return blockLines.map((line) => (line.trim() === '' ? '' : line.slice(minimumIndent))).join('\n');
}

function buildChecklistBody({ mondayPostStatus, checkedDistributionDays, totalDistributionDays }) {
  const distributionChecklist = Array.from({ length: totalDistributionDays }, (_, index) => {
    const dayNumber = index + 1;
    const checked = dayNumber <= checkedDistributionDays ? 'x' : ' ';
    return `- [${checked}] Day ${dayNumber} distribution follow-up task completed.`;
  }).join('\n');

  return `# Monday Publish Checklist

## Publish Readiness

- [x] Hero post shipped.
- [x] Reply pack queued.
- [x] Cross-channel copy drafted.

- Monday post status: ${mondayPostStatus}
- Replies sent: 12
- Objections captured: 2
- Docs/workflow updates: 2
- Creator outreach sent: 8
- Creator outreach replies: 3
- Creator collaborations: 1
- Community cross-posts: 1
- Primary channel top variant: A
- Backup channel top variant: B

## Distribution Follow-Up Execution

- Distribution follow-up status: in progress
- Distribution days completed: ${checkedDistributionDays}/${totalDistributionDays}
- Distribution completion score: ${Math.round((checkedDistributionDays / totalDistributionDays) * 100)}%
${distributionChecklist}
`;
}

function buildFirst48hControlsBlock({
  first48hExecutionPlan = 'Day 0: launch winner reinforcement. Day 1: reply-wave amplification. Day 2: proof recap.',
  routeAlignmentTarget = 'Align by first Day 1 window',
  routeGuardrail = 'Keep claims tied to measurable proof.',
  routeLaneTrigger = 'Watch lane until Day 1 replies hold above baseline.',
  routeRecommendationNow = 'Keep route controls locked and re-check after Day 1.',
  audienceRegions = 'Global + US',
  publishWindows = 'Global 13:00 UTC / US 15:00-17:00 local',
  escalationTriggerOne = 'If Day 0 response quality drops, tighten claim specificity.',
  escalationTriggerTwo = 'If Day 1 conversion stalls, switch to proof-first follow-up.'
} = {}) {
  return `<!-- weekly-growth-founder-first48h-controls-start -->

## Founder First 48h Route Controls (Auto-Synced)

- First 48h execution plan: ${first48hExecutionPlan}
- Route alignment target: ${routeAlignmentTarget}
- Route guardrail: ${routeGuardrail}
- Route lane trigger: ${routeLaneTrigger}
- Route recommendation now: ${routeRecommendationNow}
- Audience regions: ${audienceRegions}
- Publish windows: ${publishWindows}
- Escalation trigger #1: ${escalationTriggerOne}
- Escalation trigger #2: ${escalationTriggerTwo}

<!-- weekly-growth-founder-first48h-controls-end -->`;
}

function buildNarrativeComment({
  priorityRoute,
  fameVelocityScore,
  launchPosture,
  nextStandupAction,
  routeLaneStatus = 'Stable',
  routeLabMode = 'Route Compounding',
  routeAlignmentTarget = 'Aligned + Stable',
  routeGuardrail = 'Keep proof statements tied to logged outcomes.',
  routeRecommendationNow = 'Keep winner locked and scale with one proof-backed update per day.',
  distributionStrategy = 'Compounding cadence: lead with winner amplification, follow with social-proof compounding.',
  distributionDay0Lead = 'X / Threads (Global, 13:00 UTC)',
  distributionDay0Support = 'LinkedIn (US, 15:00-17:00 local)',
  first48hExecutionPlan = 'Day 0: launch winner amplification on X / Threads. Day 1: amplify strongest replies on LinkedIn. Day 2: publish a compounding proof recap.'
}) {
  return `${narrativeMarker}

## Snapshot

- Priority route: ${priorityRoute}
- Route lane status: ${routeLaneStatus}

## Fame Velocity Dashboard

- Fame velocity score: ${fameVelocityScore}/100
- Launch posture: ${launchPosture}
- Next standup action: ${nextStandupAction}

## Narrative Route Lab Controls

- Route lab mode: ${routeLabMode}
- Route alignment target: ${routeAlignmentTarget}
- Route guardrail: ${routeGuardrail}
- Route recommendation now: ${routeRecommendationNow}
- First 48h execution plan: ${first48hExecutionPlan}

## 7-Day Distribution Calendar

- Distribution strategy: ${distributionStrategy}

| Day | Lead channel | Support channel | Objective | Proof anchor |
| --- | --- | --- | --- | --- |
| Day 0 | ${distributionDay0Lead} | ${distributionDay0Support} | Launch one route-winner proof post and pin the narrative route. | Ship one proof-first narrative in the first posting window. |
`;
}

function buildMalformedNarrativeComment() {
  return `${narrativeMarker}

## Snapshot

- Priority lane: proof-first route

## Fame Velocity Dashboard

- Fame velocity score: ninety/100
- Launch posture:
`;
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', script);

  return async function runScenario({ issues, commentsByIssue, envOverrides }) {
    const outputs = {};
    const infoMessages = [];
    const warningMessages = [];

    const commentsLookup = new Map(
      Object.entries(commentsByIssue || {}).map(([issueNumber, comments]) => [
        String(issueNumber),
        Array.isArray(comments)
          ? comments.map((comment, index) => ({
              id: Number(comment.id || index + 1),
              body: String(comment.body || '')
            }))
          : []
      ])
    );

    const github = {
      paginate: async (_method, params = {}) => {
        const issueNumber = String(params.issue_number || '');
        return commentsLookup.get(issueNumber) || [];
      },
      rest: {
        issues: {
          listForRepo: async () => ({
            data: Array.isArray(issues) ? issues.map((issue) => ({ ...issue })) : []
          }),
          listComments: async ({ issue_number }) => ({
            data: (commentsLookup.get(String(issue_number)) || []).map((comment) => ({ ...comment }))
          })
        }
      }
    };

    const context = {
      repo: {
        owner: 'owner',
        repo: 'repo'
      }
    };

    const core = {
      info: (message) => infoMessages.push(String(message)),
      warning: (message) => warningMessages.push(String(message)),
      setOutput: (key, value) => {
        outputs[String(key)] = String(value);
      }
    };

    const env = {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: '2026-W22',
      ...(envOverrides || {})
    };

    await executor(github, context, core, { env });

    return {
      outputs,
      infoMessages,
      warningMessages
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const previousWeekChecklist = {
    number: 231,
    title: 'Monday Publish Checklist 2026-W23',
    body: buildChecklistBody({
      mondayPostStatus: 'posted',
      checkedDistributionDays: 6,
      totalDistributionDays: 8
    }),
    html_url: 'https://example.local/issues/231'
  };

  const baselineWeekChecklist = {
    number: 222,
    title: 'Monday Publish Checklist 2026-W22',
    body: buildChecklistBody({
      mondayPostStatus: 'posted',
      checkedDistributionDays: 5,
      totalDistributionDays: 8
    }),
    html_url: 'https://example.local/issues/222'
  };

  const scenario = await runScenario({
    issues: [
      previousWeekChecklist,
      baselineWeekChecklist,
      {
        number: 190,
        title: 'Weekly Growth Sprint 2026-W24',
        body: '- Win Card copies: 30',
        html_url: 'https://example.local/issues/190'
      }
    ],
    commentsByIssue: {
      231: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'behind the scenes route',
            fameVelocityScore: 78,
            launchPosture: 'Stabilize and scale',
            nextStandupAction: 'Log one route winner and one failed route in standup notes.',
            routeLaneStatus: 'Watch',
            routeLabMode: 'Route Re-Lock',
            routeAlignmentTarget: 'Aligned by Day 1',
            routeGuardrail: 'Keep every route update tied to one measurable proof artifact.',
            routeRecommendationNow: 'Re-lock winner, execution mode, and opportunity before next publish.',
            distributionStrategy: 'Re-lock cadence: lead with winner reinforcement, follow with conversion proof.',
            distributionDay0Lead: 'X / Threads (Global, 13:00 UTC)',
            distributionDay0Support: 'LinkedIn (US, 15:00-17:00 local)',
            first48hExecutionPlan:
              'Day 0: lead with winner re-lock post on X / Threads. Day 1: reinforce confidence with replies on LinkedIn. Day 2: publish one proof-backed winner recap.'
          })
        }
      ],
      222: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'proof first route',
            fameVelocityScore: 64,
            launchPosture: 'Recovery mode',
            nextStandupAction: 'Capture one route winner before Friday.',
            routeLaneStatus: 'Stable',
            routeLabMode: 'Route Compounding',
            routeAlignmentTarget: 'Aligned + Stable',
            routeGuardrail: 'Use proof-first claims only when evidence is current.',
            routeRecommendationNow: 'Keep route winner locked and compound proof updates.'
          })
        }
      ]
    }
  });

  assertCondition(
    scenario.outputs.source_week === '2026-W23',
    `Expected source_week=2026-W23, got ${scenario.outputs.source_week || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.baseline_week === '2026-W22',
    `Expected baseline_week=2026-W22, got ${scenario.outputs.baseline_week || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.checklist_issue_number === '231',
    `Expected checklist_issue_number=231, got ${scenario.outputs.checklist_issue_number || '(missing)'}`
  );

  assertCondition(
    scenario.outputs.narrative_route_winner === 'Behind-the-scenes route',
    `Expected narrative_route_winner=Behind-the-scenes route, got ${scenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_winner_delta === 'Proof-first route -> Behind-the-scenes route',
    `Expected narrative_route_winner_delta=Proof-first route -> Behind-the-scenes route, got ${scenario.outputs.narrative_route_winner_delta || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_trend === 'shifted from Proof-first route to Behind-the-scenes route',
    `Expected narrative_route_trend to describe shifted route, got ${scenario.outputs.narrative_route_trend || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_fame_velocity_score === '78%',
    `Expected narrative_fame_velocity_score=78%, got ${scenario.outputs.narrative_fame_velocity_score || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_fame_velocity_score_delta === '+14pp',
    `Expected narrative_fame_velocity_score_delta=+14pp, got ${scenario.outputs.narrative_fame_velocity_score_delta || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_launch_posture === 'Stabilize and scale',
    `Expected narrative_launch_posture=Stabilize and scale, got ${scenario.outputs.narrative_launch_posture || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_next_standup_action === 'Log one route winner and one failed route in standup notes.',
    `Expected narrative_next_standup_action to match fixture input, got ${scenario.outputs.narrative_next_standup_action || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_mode === 'Route Re-Lock',
    `Expected narrative_route_mode=Route Re-Lock, got ${scenario.outputs.narrative_route_mode || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_alignment_target === 'Aligned by Day 1',
    `Expected narrative_route_alignment_target=Aligned by Day 1, got ${scenario.outputs.narrative_route_alignment_target || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_lane_status === 'Watch',
    `Expected narrative_route_lane_status=Watch, got ${scenario.outputs.narrative_route_lane_status || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_guardrail === 'Keep every route update tied to one measurable proof artifact.',
    `Expected narrative_route_guardrail to match fixture input, got ${scenario.outputs.narrative_route_guardrail || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_route_control_recommendation === 'Re-lock winner, execution mode, and opportunity before next publish.',
    `Expected narrative_route_control_recommendation to match fixture input, got ${scenario.outputs.narrative_route_control_recommendation || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_distribution_strategy === 'Re-lock cadence: lead with winner reinforcement, follow with conversion proof.',
    `Expected narrative_distribution_strategy from narrative lab comment, got ${scenario.outputs.narrative_distribution_strategy || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_distribution_day0_lead === 'X / Threads (Global, 13:00 UTC)',
    `Expected narrative_distribution_day0_lead from Day 0 row, got ${scenario.outputs.narrative_distribution_day0_lead || '(missing)'}`
  );
  assertCondition(
    scenario.outputs.narrative_distribution_day0_support === 'LinkedIn (US, 15:00-17:00 local)',
    `Expected narrative_distribution_day0_support from Day 0 row, got ${scenario.outputs.narrative_distribution_day0_support || '(missing)'}`
  );
  assertCondition(
    String(scenario.outputs.narrative_distribution_recommendation || '').includes('Run re-lock cadence'),
    'Expected narrative_distribution_recommendation to follow re-lock branch.'
  );
  assertCondition(
    scenario.outputs.narrative_distribution_first_48h_plan ===
      'Day 0: lead with winner re-lock post on X / Threads. Day 1: reinforce confidence with replies on LinkedIn. Day 2: publish one proof-backed winner recap.',
    `Expected narrative_distribution_first_48h_plan to honor explicit narrative-lab plan, got ${scenario.outputs.narrative_distribution_first_48h_plan || '(missing)'}`
  );
  assertCondition(
    String(scenario.outputs.narrative_route_recommendation || '').includes('Keep Behind-the-scenes route as lead narrative route'),
    'Expected high-confidence founder narrative recommendation when fame velocity score is high.'
  );

  const noSignalScenario = await runScenario({
    issues: [previousWeekChecklist],
    commentsByIssue: {
      231: [{ body: 'No narrative marker comment yet.' }]
    },
    envOverrides: {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: ''
    }
  });

  assertCondition(
    noSignalScenario.outputs.narrative_route_winner === 'n/a',
    `Expected narrative_route_winner=n/a when marker is absent, got ${noSignalScenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    noSignalScenario.outputs.narrative_fame_velocity_score === 'n/a',
    `Expected narrative_fame_velocity_score=n/a when marker is absent, got ${noSignalScenario.outputs.narrative_fame_velocity_score || '(missing)'}`
  );
  assertCondition(
    noSignalScenario.outputs.narrative_route_mode === 'n/a',
    `Expected narrative_route_mode=n/a when marker is absent, got ${noSignalScenario.outputs.narrative_route_mode || '(missing)'}`
  );
  assertCondition(
    String(noSignalScenario.outputs.narrative_route_recommendation || '').includes('Capture founder fame narrative lab comment'),
    'Expected default narrative recommendation when marker is absent.'
  );
  assertCondition(
    String(noSignalScenario.outputs.narrative_route_control_recommendation || '').includes('Capture route mode and lane status'),
    'Expected default narrative control recommendation when marker is absent.'
  );
  assertCondition(
    String(noSignalScenario.outputs.narrative_distribution_first_48h_plan || '').includes('Capture Day 0 lead/support lanes first'),
    'Expected default first-48h execution plan recommendation when marker is absent.'
  );

  const controlsFallbackChecklist = {
    number: 232,
    title: 'Monday Publish Checklist 2026-W23',
    body: `${buildChecklistBody({
      mondayPostStatus: 'posted',
      checkedDistributionDays: 6,
      totalDistributionDays: 8
    }).trimEnd()}

${buildFirst48hControlsBlock({
      first48hExecutionPlan:
        'Day 0: ship route-lock lead post. Day 1: amplify highest-conversion replies. Day 2: publish one compounding proof recap.',
      routeAlignmentTarget: 'Align by Day 1 close',
      routeGuardrail: 'Every claim maps to one logged KPI delta.',
      routeLaneTrigger: 'Watch: if Day 1 reply quality drops below baseline, move to Route Re-Lock.',
      routeRecommendationNow: 'Re-lock route controls before next publish window.'
    })}
`,
    html_url: 'https://example.local/issues/232'
  };

  const controlsFallbackScenario = await runScenario({
    issues: [controlsFallbackChecklist],
    commentsByIssue: {
      232: [{ body: 'No narrative marker comment yet.' }]
    },
    envOverrides: {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: ''
    }
  });

  assertCondition(
    controlsFallbackScenario.outputs.narrative_route_alignment_target === 'Align by Day 1 close',
    `Expected checklist controls fallback to populate narrative_route_alignment_target, got ${controlsFallbackScenario.outputs.narrative_route_alignment_target || '(missing)'}`
  );
  assertCondition(
    controlsFallbackScenario.outputs.narrative_route_lane_status === 'Watch: if Day 1 reply quality drops below baseline, move to Route Re-Lock.',
    `Expected checklist controls fallback to populate narrative_route_lane_status from route lane trigger, got ${controlsFallbackScenario.outputs.narrative_route_lane_status || '(missing)'}`
  );
  assertCondition(
    controlsFallbackScenario.outputs.narrative_route_guardrail === 'Every claim maps to one logged KPI delta.',
    `Expected checklist controls fallback to populate narrative_route_guardrail, got ${controlsFallbackScenario.outputs.narrative_route_guardrail || '(missing)'}`
  );
  assertCondition(
    controlsFallbackScenario.outputs.narrative_route_control_recommendation === 'Re-lock route controls before next publish window.',
    `Expected checklist controls fallback to populate narrative_route_control_recommendation, got ${controlsFallbackScenario.outputs.narrative_route_control_recommendation || '(missing)'}`
  );
  assertCondition(
    controlsFallbackScenario.outputs.narrative_distribution_first_48h_plan ===
      'Day 0: ship route-lock lead post. Day 1: amplify highest-conversion replies. Day 2: publish one compounding proof recap.',
    `Expected checklist controls fallback to populate narrative_distribution_first_48h_plan, got ${controlsFallbackScenario.outputs.narrative_distribution_first_48h_plan || '(missing)'}`
  );

  const noBaselineScenario = await runScenario({
    issues: [previousWeekChecklist],
    commentsByIssue: {
      231: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'BTS route',
            fameVelocityScore: 63,
            launchPosture: 'Scale',
            nextStandupAction: 'Ship one founder BTS walkthrough post this week.'
          })
        }
      ]
    },
    envOverrides: {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: ''
    }
  });

  assertCondition(
    noBaselineScenario.outputs.narrative_route_winner === 'Behind-the-scenes route',
    `Expected no-baseline winner to normalize BTS route, got ${noBaselineScenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    noBaselineScenario.outputs.narrative_route_trend === 'first tracked winner: Behind-the-scenes route',
    `Expected first tracked winner trend without baseline, got ${noBaselineScenario.outputs.narrative_route_trend || '(missing)'}`
  );
  assertCondition(
    noBaselineScenario.outputs.narrative_route_winner_delta === 'n/a',
    `Expected narrative_route_winner_delta=n/a without baseline, got ${noBaselineScenario.outputs.narrative_route_winner_delta || '(missing)'}`
  );

  const malformedScenario = await runScenario({
    issues: [previousWeekChecklist],
    commentsByIssue: {
      231: [
        {
          body: buildMalformedNarrativeComment()
        }
      ]
    },
    envOverrides: {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: ''
    }
  });

  assertCondition(
    malformedScenario.outputs.narrative_route_winner === 'n/a',
    `Expected malformed narrative comment to keep winner n/a, got ${malformedScenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    malformedScenario.outputs.narrative_fame_velocity_score === 'n/a',
    `Expected malformed narrative comment to keep fame velocity n/a, got ${malformedScenario.outputs.narrative_fame_velocity_score || '(missing)'}`
  );
  assertCondition(
    String(malformedScenario.outputs.narrative_route_recommendation || '').includes('Capture founder fame narrative lab comment'),
    'Expected malformed narrative comment to fall back to capture recommendation.'
  );
  assertCondition(
    String(malformedScenario.outputs.narrative_route_control_recommendation || '').includes('Capture route mode and lane status'),
    'Expected malformed narrative comment to fall back to control-capture recommendation.'
  );

  const synonymScenario = await runScenario({
    issues: [previousWeekChecklist, baselineWeekChecklist],
    commentsByIssue: {
      231: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'objection handler route',
            fameVelocityScore: 67,
            launchPosture: 'Watch and iterate',
            nextStandupAction: 'Log one objection-breaker win with proof screenshot.'
          })
        }
      ],
      222: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'proof-first route',
            fameVelocityScore: 59,
            launchPosture: 'Stabilize',
            nextStandupAction: 'Capture one proof-first win before Friday.'
          })
        }
      ]
    }
  });

  assertCondition(
    synonymScenario.outputs.narrative_route_winner === 'Objection-breaker route',
    `Expected objection-handler synonym to normalize, got ${synonymScenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    synonymScenario.outputs.narrative_route_winner_delta === 'Proof-first route -> Objection-breaker route',
    `Expected shifted delta into objection-breaker route, got ${synonymScenario.outputs.narrative_route_winner_delta || '(missing)'}`
  );
  assertCondition(
    String(synonymScenario.outputs.narrative_route_recommendation || '').includes('Validate Objection-breaker route as the new route winner'),
    'Expected shifted-route recommendation branch for normalized route synonyms.'
  );

  const recoveryScenario = await runScenario({
    issues: [previousWeekChecklist, baselineWeekChecklist],
    commentsByIssue: {
      231: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'proof first route',
            fameVelocityScore: 54,
            launchPosture: 'Recovery mode',
            nextStandupAction: 'Run one route remix test and log outcomes.'
          })
        }
      ],
      222: [
        {
          body: buildNarrativeComment({
            priorityRoute: 'proof-first route',
            fameVelocityScore: 56,
            launchPosture: 'Recovery mode',
            nextStandupAction: 'Keep logging route outcomes.'
          })
        }
      ]
    }
  });

  assertCondition(
    recoveryScenario.outputs.narrative_route_winner === 'Proof-first route',
    `Expected recovery scenario to keep proof-first winner, got ${recoveryScenario.outputs.narrative_route_winner || '(missing)'}`
  );
  assertCondition(
    recoveryScenario.outputs.narrative_route_trend === 'holding Proof-first route',
    `Expected holding trend for recovery scenario, got ${recoveryScenario.outputs.narrative_route_trend || '(missing)'}`
  );
  assertCondition(
    String(recoveryScenario.outputs.narrative_route_recommendation || '').includes('Route Remix Matrix fallback'),
    'Expected recovery launch posture branch to recommend Route Remix Matrix fallback.'
  );
}

runFixtureSuite()
  .then(() => {
    console.log('Founder narrative route fixture checks passed.');
  })
  .catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
