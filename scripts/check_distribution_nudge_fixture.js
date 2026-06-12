#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const nudgeMarker = '<!-- weekly-growth-distribution-nudge -->';
const actionItemsMarker = '<!-- weekly-growth-distribution-action-items -->';
const escalationStartMarker = '<!-- weekly-growth-distribution-escalation-start -->';
const escalationEndMarker = '<!-- weekly-growth-distribution-escalation-end -->';
const day0Label = 'Day 0 launch proof-first post + initial replies completed.';
const day1Label = 'Day 1 support-channel workflow follow-up completed.';
const day2Label = 'Day 2 creator/community follow-up wave 1 completed.';

function leadingSpaces(value) {
  const match = String(value || '').match(/^(\s*)/);
  return match ? match[1].length : 0;
}

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function extractNudgeScript(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const stepLineIndex = lines.findIndex((line) =>
    line.includes('- name: Upsert distribution execution nudge')
  );
  assertCondition(stepLineIndex >= 0, 'Could not find distribution nudge step.');

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

  assertCondition(scriptLineIndex >= 0, 'Could not find script block for distribution nudge step.');

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
  assertCondition(nonEmptyLines.length > 0, 'Distribution nudge script block is empty.');
  const minimumIndent = Math.min(...nonEmptyLines.map((line) => leadingSpaces(line)));
  return blockLines.map((line) => (line.trim() === '' ? '' : line.slice(minimumIndent))).join('\n');
}

function buildChecklistBody({ day0, day1, day2, withEscalation }) {
  const escalationBlock = withEscalation
    ? `${escalationStartMarker}

## Distribution Escalation Queue (Auto-Managed)

- Source week: 2026-W23
- Trigger reason: distribution score 35% below 75%
- Escalated Day 0-Day 2 tasks: 2
- Last refresh: 2026-06-01T00:00:00.000Z
- [ ] Escalation: ${day0Label} (within 6 hours)
- [ ] Escalation: ${day2Label} (within 24 hours)

${escalationEndMarker}`
    : '';

  return `# Monday Publish Checklist: 2026-W24

## Distribution Follow-Up Execution

- Distribution follow-up status: in progress
- Distribution days completed: 2/8
- Distribution completion score: 25%
- [${day0}] ${day0Label}
- [${day1}] ${day1Label}
- [${day2}] ${day2Label}
- [ ] Day 3 objection-handler repost completed.
- [ ] Day 4 creator/community follow-up wave 2 completed.
- [ ] Day 5 docs/workflow conversion completed.
- [ ] Day 6 proof recap + collaboration nudge completed.
- [ ] Day 7 Friday review handoff completed.

${escalationBlock}
`;
}

function countMarkerComments(comments, marker) {
  return comments.filter((comment) => String(comment.body || '').includes(marker)).length;
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', script);

  return async function runScenario({ envOverrides, issueBody, comments }) {
    const outputs = {};
    const infoMessages = [];
    let currentIssueBody = String(issueBody || '');
    const currentComments = Array.isArray(comments)
      ? comments.map((comment, index) => ({
          id: Number(comment.id || index + 1),
          body: String(comment.body || '')
        }))
      : [];
    let nextCommentId = currentComments.reduce((max, comment) => Math.max(max, Number(comment.id) || 0), 0) + 1;

    const github = {
      paginate: async () => currentComments.map((comment) => ({ ...comment })),
      rest: {
        issues: {
          listComments: async () => ({ data: currentComments.map((comment) => ({ ...comment })) }),
          get: async () => ({ data: { body: currentIssueBody } }),
          update: async ({ body }) => {
            currentIssueBody = String(body || '');
            return { data: { body: currentIssueBody } };
          },
          createComment: async ({ body }) => {
            const created = {
              id: nextCommentId,
              body: String(body || ''),
              html_url: `https://example.local/comment/${nextCommentId}`
            };
            nextCommentId += 1;
            currentComments.push(created);
            return { data: created };
          },
          updateComment: async ({ comment_id, body }) => {
            const targetIndex = currentComments.findIndex(
              (comment) => String(comment.id) === String(comment_id)
            );
            assertCondition(targetIndex >= 0, `Cannot update missing comment #${comment_id}.`);
            currentComments[targetIndex] = {
              ...currentComments[targetIndex],
              body: String(body || ''),
              html_url: `https://example.local/comment/${comment_id}`
            };
            return { data: currentComments[targetIndex] };
          },
          deleteComment: async ({ comment_id }) => {
            const targetIndex = currentComments.findIndex(
              (comment) => String(comment.id) === String(comment_id)
            );
            if (targetIndex >= 0) {
              currentComments.splice(targetIndex, 1);
            }
            return { data: {} };
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
      }
    };

    const env = {
      ISSUE_NUMBER: '17',
      SOURCE_WEEK: '2026-W24',
      DISTRIBUTION_STATUS: 'in progress',
      DISTRIBUTION_DAYS_COMPLETED: '2',
      DISTRIBUTION_DAYS_TOTAL: '8',
      DISTRIBUTION_SCORE: '25%',
      DISTRIBUTION_SCORE_DELTA: '-10pp',
      CHANNEL_MIX_RECOMMENDATION: 'Maintain a primary-led 60/40 mix and complete Day-0 to Day-7 follow-up cadence.',
      CHANNEL_ROI_PREFERRED_CHANNEL: 'primary',
      CHANNEL_ROI_RECOMMENDATION: 'Lead with primary channel this week.',
      DISTRIBUTION_COMPLETION_THRESHOLD: '75',
      ...(envOverrides || {})
    };

    await executor(github, context, core, { env });

    return {
      outputs,
      infoMessages,
      issueBody: currentIssueBody,
      comments: currentComments.map((comment) => ({ ...comment }))
    };
  };
}

async function runFixtureSuite() {
  const script = extractNudgeScript(workflowPath);
  const runScenario = createRunner(script);

  const triggeredWithGaps = await runScenario({
    envOverrides: {
      DISTRIBUTION_STATUS: 'in progress',
      DISTRIBUTION_SCORE: '42%',
      DISTRIBUTION_COMPLETION_THRESHOLD: '75'
    },
    issueBody: buildChecklistBody({
      day0: ' ',
      day1: 'x',
      day2: ' ',
      withEscalation: false
    }),
    comments: []
  });

  assertCondition(
    triggeredWithGaps.outputs.nudge_status === 'triggered',
    'Expected nudge_status=triggered when score/status is below threshold.'
  );
  assertCondition(
    triggeredWithGaps.outputs.escalation_status === 'active',
    'Expected escalation_status=active when Day 0-Day 2 gaps exist.'
  );
  assertCondition(
    triggeredWithGaps.outputs.threshold_used === '75',
    'Expected threshold_used output to preserve parsed threshold.'
  );
  assertCondition(
    triggeredWithGaps.outputs.normalized_distribution_status === 'in progress',
    'Expected normalized_distribution_status output to be in progress.'
  );
  assertCondition(
    triggeredWithGaps.outputs.nudge_comment_action === 'created',
    'Expected nudge comment action to be created when no existing nudge comment exists.'
  );
  assertCondition(
    triggeredWithGaps.outputs.action_items_comment_action === 'created',
    'Expected action-items comment action to be created when Day 0-Day 2 gaps exist.'
  );
  assertCondition(
    triggeredWithGaps.outputs.escalation_block_action === 'upserted',
    'Expected escalation block action to be upserted with unresolved Day 0-Day 2 tasks.'
  );
  assertCondition(
    triggeredWithGaps.outputs.nudge_duplicate_comments_cleared === '0' &&
      triggeredWithGaps.outputs.action_items_duplicate_comments_cleared === '0',
    'Expected duplicate comment counters to remain zero when no pre-existing comments exist.'
  );
  assertCondition(
    triggeredWithGaps.outputs.escalated_tasks_count === '2',
    'Expected two escalated tasks for Day 0 and Day 2.'
  );
  assertCondition(
    countMarkerComments(triggeredWithGaps.comments, nudgeMarker) === 1,
    'Expected exactly one distribution nudge comment.'
  );
  assertCondition(
    countMarkerComments(triggeredWithGaps.comments, actionItemsMarker) === 1,
    'Expected exactly one distribution action-items comment.'
  );
  assertCondition(
    triggeredWithGaps.issueBody.includes(escalationStartMarker) &&
      triggeredWithGaps.issueBody.includes(escalationEndMarker),
    'Expected escalation queue block to be inserted into checklist body.'
  );
  assertCondition(
    triggeredWithGaps.issueBody.includes(`Escalation: ${day0Label}`) &&
      triggeredWithGaps.issueBody.includes(`Escalation: ${day2Label}`),
    'Expected escalation queue block to include Day 0 and Day 2 tasks.'
  );

  const recoveredScenario = await runScenario({
    envOverrides: {
      DISTRIBUTION_STATUS: 'completed',
      DISTRIBUTION_SCORE: '92%',
      DISTRIBUTION_COMPLETION_THRESHOLD: '75'
    },
    issueBody: buildChecklistBody({
      day0: 'x',
      day1: 'x',
      day2: 'x',
      withEscalation: true
    }),
    comments: [
      { id: 100, body: `${nudgeMarker}\nlegacy nudge 1` },
      { id: 101, body: `${nudgeMarker}\nlegacy nudge 2` },
      { id: 102, body: `${actionItemsMarker}\nlegacy action 1` },
      { id: 103, body: `${actionItemsMarker}\nlegacy action 2` }
    ]
  });

  assertCondition(
    recoveredScenario.outputs.nudge_status === 'cleared',
    'Expected nudge_status=cleared when distribution recovery is complete.'
  );
  assertCondition(
    recoveredScenario.outputs.escalation_status === 'cleared',
    'Expected escalation_status=cleared after recovery.'
  );
  assertCondition(
    recoveredScenario.outputs.nudge_comment_action === 'deleted',
    'Expected nudge comment action to be deleted after recovery.'
  );
  assertCondition(
    recoveredScenario.outputs.action_items_comment_action === 'deleted',
    'Expected action-items comment action to be deleted after recovery.'
  );
  assertCondition(
    recoveredScenario.outputs.escalation_block_action === 'cleared',
    'Expected escalation block action to be cleared after recovery.'
  );
  assertCondition(
    recoveredScenario.outputs.nudge_duplicate_comments_cleared === '1' &&
      recoveredScenario.outputs.action_items_duplicate_comments_cleared === '1',
    'Expected duplicate counters to report cleared duplicate marker comments.'
  );
  assertCondition(
    recoveredScenario.outputs.escalated_tasks_count === '0',
    'Expected escalated_tasks_count=0 after recovery.'
  );
  assertCondition(
    countMarkerComments(recoveredScenario.comments, nudgeMarker) === 0,
    'Expected all nudge comments to be removed after recovery.'
  );
  assertCondition(
    countMarkerComments(recoveredScenario.comments, actionItemsMarker) === 0,
    'Expected all action-items comments to be removed after recovery.'
  );
  assertCondition(
    !recoveredScenario.issueBody.includes(escalationStartMarker) &&
      !recoveredScenario.issueBody.includes(escalationEndMarker),
    'Expected escalation queue block to be removed after recovery.'
  );

  const triggeredWithoutGaps = await runScenario({
    envOverrides: {
      DISTRIBUTION_STATUS: 'in progress',
      DISTRIBUTION_SCORE: '70%',
      DISTRIBUTION_COMPLETION_THRESHOLD: '75'
    },
    issueBody: buildChecklistBody({
      day0: 'x',
      day1: 'x',
      day2: 'x',
      withEscalation: true
    }),
    comments: [
      { id: 201, body: `${nudgeMarker}\nolder nudge` },
      { id: 202, body: `${nudgeMarker}\nnewer nudge` },
      { id: 203, body: `${actionItemsMarker}\nolder action` },
      { id: 204, body: `${actionItemsMarker}\nnewer action` }
    ]
  });

  assertCondition(
    triggeredWithoutGaps.outputs.nudge_status === 'triggered',
    'Expected nudge_status=triggered when score is below threshold.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.escalation_status === 'no-day0-2-gaps',
    'Expected no-day0-2-gaps when early distribution tasks are complete.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.nudge_comment_action === 'updated',
    'Expected nudge comment action to be updated when a prior nudge comment exists.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.action_items_comment_action === 'deleted',
    'Expected action-items comment action to be deleted when early tasks are complete.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.escalation_block_action === 'cleared',
    'Expected escalation block action to be cleared when no early-day gaps remain.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.nudge_duplicate_comments_cleared === '1' &&
      triggeredWithoutGaps.outputs.action_items_duplicate_comments_cleared === '1',
    'Expected duplicate counters to report one stale duplicate removed per marker.'
  );
  assertCondition(
    triggeredWithoutGaps.outputs.escalated_tasks_count === '0',
    'Expected escalated_tasks_count=0 when Day 0-Day 2 tasks are complete.'
  );
  assertCondition(
    countMarkerComments(triggeredWithoutGaps.comments, nudgeMarker) === 1,
    'Expected stale duplicate nudge comments to collapse to one active comment.'
  );
  assertCondition(
    countMarkerComments(triggeredWithoutGaps.comments, actionItemsMarker) === 0,
    'Expected action-items comments to clear when Day 0-Day 2 tasks are complete.'
  );
  assertCondition(
    !triggeredWithoutGaps.issueBody.includes(escalationStartMarker) &&
      !triggeredWithoutGaps.issueBody.includes(escalationEndMarker),
    'Expected escalation queue block to clear when no early-day gaps remain.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Distribution nudge fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Distribution nudge fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
