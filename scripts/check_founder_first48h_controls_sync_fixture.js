#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Sync founder first-48h controls into Monday checklist';
const controlsStartMarker = '<!-- weekly-growth-founder-first48h-controls-start -->';
const controlsEndMarker = '<!-- weekly-growth-founder-first48h-controls-end -->';

function leadingSpaces(value) {
  const match = String(value || '').match(/^(\s*)/);
  return match ? match[1].length : 0;
}

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function escapeRegex(value) {
  return String(value || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
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

function countControlBlocks(body) {
  const markerRegex = new RegExp(escapeRegex(controlsStartMarker), 'g');
  return (String(body || '').match(markerRegex) || []).length;
}

function buildPackBody({
  first48hExecutionPlan,
  routeAlignmentTarget,
  routeGuardrail,
  routeLaneTrigger,
  routeRecommendationNow,
  audienceRegions,
  publishWindows,
  escalationTriggerOne,
  escalationTriggerTwo
}) {
  return `<!-- weekly-growth-founder-first48h-post-pack -->

# Founder First 48h Post Pack: 2099-W02

## Signal Snapshot

- First 48h execution plan: ${first48hExecutionPlan}

## Route Control Handshake (First 48h)

- Route alignment target: ${routeAlignmentTarget}
- Route guardrail: ${routeGuardrail}
- Route lane trigger: ${routeLaneTrigger}
- Route recommendation now: ${routeRecommendationNow}
- Audience regions: ${audienceRegions}
- Publish windows: ${publishWindows}

## Escalation & Adaptation Triggers

1. ${escalationTriggerOne}
2. ${escalationTriggerTwo}
`;
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', 'require', script);

  return async function runScenario({ issueBody, packBody }) {
    const outputs = {};
    const infoMessages = [];
    let currentIssueBody = String(issueBody || '');
    let updateCallCount = 0;
    let getCallCount = 0;

    const github = {
      rest: {
        issues: {
          get: async () => {
            getCallCount += 1;
            return { data: { body: currentIssueBody } };
          },
          update: async ({ body }) => {
            updateCallCount += 1;
            currentIssueBody = String(body || '');
            return { data: { body: currentIssueBody } };
          }
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
      setOutput: (key, value) => {
        outputs[String(key)] = String(value);
      },
      setFailed: (message) => {
        throw new Error(`Unexpected setFailed call: ${String(message)}`);
      }
    };

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-first48h-controls-sync-'));
    const packPath = path.join(tmpDir, 'founder-first48h-post-pack.md');
    fs.writeFileSync(packPath, String(packBody || ''), 'utf8');

    try {
      await executor(github, context, core, {
        env: {
          ISSUE_NUMBER: '17',
          FOUNDER_FIRST48H_POST_PACK_PATH: packPath
        }
      }, require);
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }

    return {
      outputs,
      infoMessages,
      issueBody: currentIssueBody,
      updateCallCount,
      getCallCount
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const baseChecklistBody = `# Monday Publish Checklist

## Publish Readiness
- [x] Hero post shipped.

## Monday Draft Source
- Draft block placeholder.
`;

  const initialPackBody = buildPackBody({
    first48hExecutionPlan: 'Day 0 launch winner route; Day 1 reinforce replies; Day 2 publish proof recap.',
    routeAlignmentTarget: 'Aligned + Stable',
    routeGuardrail: 'Keep each route claim tied to measurable proof.',
    routeLaneTrigger: 'Escalate when Day 1 reply quality drops below baseline.',
    routeRecommendationNow: 'Keep winner route locked for 48h.',
    audienceRegions: 'Global + US',
    publishWindows: '13:00 UTC / 18:00 UTC',
    escalationTriggerOne: 'If Day 0 launch underperforms, tighten proof statement.',
    escalationTriggerTwo: 'If Day 1 conversion stalls, switch reply ladder.'
  });

  const insertedScenario = await runScenario({
    issueBody: baseChecklistBody,
    packBody: initialPackBody
  });

  assertCondition(
    insertedScenario.getCallCount === 1 && insertedScenario.updateCallCount === 1,
    'Expected one get and one update call when inserting founder first-48h controls block.'
  );
  assertCondition(
    insertedScenario.issueBody.includes('## Founder First 48h Route Controls (Auto-Synced)'),
    'Expected synced founder first-48h controls heading in checklist body.'
  );
  assertCondition(
    insertedScenario.issueBody.includes('- First 48h execution plan: Day 0 launch winner route; Day 1 reinforce replies; Day 2 publish proof recap.'),
    'Expected founder first-48h execution plan value in synced checklist body.'
  );
  assertCondition(
    insertedScenario.issueBody.indexOf(controlsStartMarker) < insertedScenario.issueBody.indexOf('## Monday Draft Source'),
    'Expected founder first-48h controls block inserted before Monday Draft Source heading.'
  );
  assertCondition(
    countControlBlocks(insertedScenario.issueBody) === 1,
    'Expected exactly one founder first-48h controls block after insertion.'
  );
  assertCondition(
    insertedScenario.outputs.first48h_execution_plan ===
      'Day 0 launch winner route; Day 1 reinforce replies; Day 2 publish proof recap.',
    'Expected founder first-48h execution-plan output to match extracted value.'
  );
  assertCondition(
    insertedScenario.outputs.route_alignment_target === 'Aligned + Stable',
    'Expected founder route-alignment-target output to match extracted value.'
  );
  assertCondition(
    insertedScenario.outputs.route_lane_trigger ===
      'Escalate when Day 1 reply quality drops below baseline.',
    'Expected founder route-lane-trigger output to match extracted value.'
  );
  assertCondition(
    insertedScenario.infoMessages.some((message) =>
      message.includes('Synced founder first-48h route controls into Monday checklist issue #17.')
    ),
    'Expected sync log when inserting founder first-48h controls block.'
  );

  const replacementPackBody = buildPackBody({
    first48hExecutionPlan: 'Day 0 publish route lock; Day 1 run objection ladder; Day 2 compounding closeout.',
    routeAlignmentTarget: 'Watch + Reinforce',
    routeGuardrail: 'Use one proof anchor per lane.',
    routeLaneTrigger: 'Escalate if standup route score falls two points.',
    routeRecommendationNow: 'Hold route winner through next publish window.',
    audienceRegions: 'US + EMEA',
    publishWindows: '14:00 UTC / 20:00 UTC',
    escalationTriggerOne: 'If Day 0 replies are vague, tighten CTA.',
    escalationTriggerTwo: 'If Day 1 quality stalls, shift support lane.'
  });

  const replacedScenario = await runScenario({
    issueBody: insertedScenario.issueBody,
    packBody: replacementPackBody
  });

  assertCondition(
    replacedScenario.updateCallCount === 1,
    'Expected founder first-48h controls block to be replaced when values change.'
  );
  assertCondition(
    countControlBlocks(replacedScenario.issueBody) === 1,
    'Expected exactly one founder first-48h controls block after replacement.'
  );
  assertCondition(
    replacedScenario.issueBody.includes('- First 48h execution plan: Day 0 publish route lock; Day 1 run objection ladder; Day 2 compounding closeout.'),
    'Expected replaced founder first-48h execution plan value in checklist body.'
  );
  assertCondition(
    !replacedScenario.issueBody.includes('Day 0 launch winner route; Day 1 reinforce replies; Day 2 publish proof recap.'),
    'Expected old founder first-48h execution plan value to be removed after replacement.'
  );

  const upToDateScenario = await runScenario({
    issueBody: replacedScenario.issueBody,
    packBody: replacementPackBody
  });

  assertCondition(
    upToDateScenario.updateCallCount === 0,
    'Expected no checklist update when founder first-48h controls block is already up to date.'
  );
  assertCondition(
    upToDateScenario.infoMessages.some((message) =>
      message.includes('Founder first-48h route controls already up to date in Monday checklist issue #17.')
    ),
    'Expected up-to-date log when founder first-48h controls block does not change.'
  );

  const fallbackPackBody = `# Founder First 48h Post Pack: 2099-W02

## Signal Snapshot
- Narrative route winner: Distribution Remix
`;

  const fallbackScenario = await runScenario({
    issueBody: baseChecklistBody,
    packBody: fallbackPackBody
  });

  assertCondition(
    fallbackScenario.updateCallCount === 1,
    'Expected checklist update when fallback founder first-48h values are inserted.'
  );
  assertCondition(
    fallbackScenario.issueBody.includes('- First 48h execution plan: n/a'),
    'Expected fallback founder first-48h execution plan value to render as n/a.'
  );
  assertCondition(
    fallbackScenario.issueBody.includes('- Route alignment target: n/a'),
    'Expected fallback founder route alignment target value to render as n/a.'
  );
  assertCondition(
    fallbackScenario.issueBody.includes('- Route lane trigger: n/a'),
    'Expected fallback founder route lane trigger value to render as n/a.'
  );
  assertCondition(
    fallbackScenario.outputs.first48h_execution_plan === 'n/a' &&
      fallbackScenario.outputs.route_alignment_target === 'n/a' &&
      fallbackScenario.outputs.route_lane_trigger === 'n/a',
    'Expected fallback founder first-48h outputs to resolve to n/a.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder first-48h controls sync fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder first-48h controls sync fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
