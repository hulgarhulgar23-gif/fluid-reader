#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Reconcile founder narrative route critical escalation comment';
const marker = '<!-- weekly-growth-founder-narrative-route-critical -->';

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

function isoTimestampHoursAgo(hoursAgo) {
  return new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString();
}

function buildCriticalComment(criticalOccurrences) {
  return `${marker}

## Founder Narrative Route Critical Escalation

- Status: active
- Critical trigger: route-recovery+critical-lane
- Critical occurrences this week: ${criticalOccurrences}
- Critical threshold: 2
- Critical escalation status: active
- Incident issue: #98
- Incident owner candidates: @ops-owner, @fallback
- Incident owner: @ops-owner
- Incident owner attempts: @ops-owner:assigned
- Incident owner action: assigned
- Review run: https://example.local/run/old
- Action: Run Route Recovery playbook before next publish window.
`;
}

function countMarkerComments(comments) {
  return comments.filter((comment) => String(comment.body || '').includes(marker)).length;
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', script);

  return async function runScenario({ envOverrides, comments }) {
    const outputs = {};
    const infoMessages = [];
    const nowIso = new Date().toISOString();
    const currentComments = Array.isArray(comments)
      ? comments.map((comment, index) => ({
          id: Number(comment.id || index + 1),
          body: String(comment.body || ''),
          created_at: comment.created_at || nowIso,
          updated_at: comment.updated_at || comment.created_at || nowIso,
          html_url: comment.html_url || `https://example.local/comment/${Number(comment.id || index + 1)}`
        }))
      : [];
    let nextCommentId =
      currentComments.reduce((max, comment) => Math.max(max, Number(comment.id) || 0), 0) + 1;

    const github = {
      paginate: async () => currentComments.map((comment) => ({ ...comment })),
      rest: {
        issues: {
          listComments: async () => ({ data: currentComments.map((comment) => ({ ...comment })) }),
          createComment: async ({ body }) => {
            const createdAt = new Date().toISOString();
            const created = {
              id: nextCommentId,
              body: String(body || ''),
              created_at: createdAt,
              updated_at: createdAt,
              html_url: `https://example.local/comment/${nextCommentId}`
            };
            nextCommentId += 1;
            currentComments.push(created);
            return { data: { ...created } };
          },
          updateComment: async ({ comment_id, body }) => {
            const targetIndex = currentComments.findIndex(
              (comment) => String(comment.id) === String(comment_id)
            );
            assertCondition(targetIndex >= 0, `Cannot update missing comment #${comment_id}.`);
            currentComments[targetIndex] = {
              ...currentComments[targetIndex],
              body: String(body || ''),
              updated_at: new Date().toISOString()
            };
            return { data: { ...currentComments[targetIndex] } };
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
      CHECKLIST_ISSUE_NUMBER: '17',
      CRITICAL_STATE: 'true',
      CRITICAL_TRIGGER: 'route-recovery+critical-lane',
      CRITICAL_OCCURRENCES: '2',
      CRITICAL_THRESHOLD: '2',
      CRITICAL_ESCALATED: 'true',
      INCIDENT_ISSUE_NUMBER: '98',
      CRITICAL_ASSIGNEE: 'ops-owner',
      CRITICAL_ASSIGNEE_CANDIDATES: 'ops-owner,fallback',
      CRITICAL_ASSIGNEE_ATTEMPTS: '@ops-owner:assigned',
      CRITICAL_ASSIGNEE_ACTION: 'assigned',
      ROUTE_MODE: 'Route Recovery',
      ROUTE_ALIGNMENT_TARGET: 'Aligned by Day 1',
      ROUTE_LANE_STATUS: 'Critical',
      ROUTE_GUARDRAIL: 'Keep every route update tied to one measurable proof artifact.',
      ROUTE_CONTROL_RECOMMENDATION: 'Run Route Recovery and re-lock winner before next publish.',
      ROUTE_RECOMMENDATION: 'Use Route Recovery until the lane exits critical status.',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24',
      CRITICAL_COMMENT_MIN_OCCURRENCE_DELTA: '2',
      RUN_URL: 'https://example.local/run/current',
      ...(envOverrides || {})
    };

    await executor(github, context, core, { env });

    return {
      outputs,
      infoMessages,
      comments: currentComments.map((comment) => ({ ...comment }))
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const createdScenario = await runScenario({ comments: [] });
  assertCondition(
    createdScenario.outputs.critical_comment_action === 'created',
    'Expected narrative critical comment action=created when no prior marker comment exists.'
  );
  assertCondition(
    createdScenario.outputs.critical_comment_policy_reason === 'critical-state-active-created',
    'Expected narrative critical comment created policy reason.'
  );
  assertCondition(
    createdScenario.outputs.critical_comment_occurrence_delta === '2',
    'Expected created occurrence delta to equal current critical occurrence count.'
  );
  assertCondition(
    countMarkerComments(createdScenario.comments) === 1,
    'Expected one narrative critical marker comment after create scenario.'
  );

  const cooldownSkipScenario = await runScenario({
    envOverrides: {
      CRITICAL_OCCURRENCES: '3',
      CRITICAL_COMMENT_MIN_OCCURRENCE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 301,
        body: buildCriticalComment(2),
        created_at: isoTimestampHoursAgo(1),
        updated_at: isoTimestampHoursAgo(1)
      },
      {
        id: 302,
        body: buildCriticalComment(1),
        created_at: isoTimestampHoursAgo(8),
        updated_at: isoTimestampHoursAgo(8)
      }
    ]
  });
  const cooldownSkipPrimary = cooldownSkipScenario.comments.find((comment) => comment.id === 301);
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_action === 'cooldown-delta-skip',
    'Expected cooldown-delta-skip when occurrence delta is below threshold during cooldown.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_cooldown_active === 'true',
    'Expected cooldown active output when narrative critical update is skipped.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_policy_reason ===
      'within-cooldown-and-delta-below-threshold',
    'Expected cooldown policy reason for narrative critical comment skip.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_occurrence_delta === '1',
    'Expected occurrence delta to be computed from existing comment count.'
  );
  assertCondition(
    cooldownSkipPrimary &&
      String(cooldownSkipPrimary.body || '').includes('- Critical occurrences this week: 2'),
    'Expected primary comment body to remain unchanged when cooldown skip is active.'
  );
  assertCondition(
    countMarkerComments(cooldownSkipScenario.comments) === 1,
    'Expected duplicate marker comments to dedupe even during cooldown skip.'
  );

  const cooldownUpdateScenario = await runScenario({
    envOverrides: {
      CRITICAL_OCCURRENCES: '5',
      CRITICAL_COMMENT_MIN_OCCURRENCE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 401,
        body: buildCriticalComment(2),
        created_at: isoTimestampHoursAgo(2),
        updated_at: isoTimestampHoursAgo(2)
      }
    ]
  });
  const cooldownUpdated = cooldownUpdateScenario.comments.find((comment) => comment.id === 401);
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_action === 'updated',
    'Expected narrative critical comment action=updated when delta reaches threshold during cooldown.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_policy_reason ===
      'updated-within-cooldown-delta-threshold-met',
    'Expected within-cooldown update policy reason when delta threshold is met.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_occurrence_delta === '3',
    'Expected occurrence delta to capture increase over previous comment count.'
  );
  assertCondition(
    cooldownUpdated && String(cooldownUpdated.body || '').includes('- Critical occurrences this week: 5'),
    'Expected comment body to refresh with latest occurrence count when updated.'
  );

  const cooldownExpiredScenario = await runScenario({
    envOverrides: {
      CRITICAL_OCCURRENCES: '6',
      CRITICAL_COMMENT_MIN_OCCURRENCE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 501,
        body: buildCriticalComment(5),
        created_at: isoTimestampHoursAgo(30),
        updated_at: isoTimestampHoursAgo(30)
      }
    ]
  });
  assertCondition(
    cooldownExpiredScenario.outputs.critical_comment_action === 'updated' &&
      cooldownExpiredScenario.outputs.critical_comment_policy_reason === 'updated-cooldown-expired',
    'Expected cooldown-expired policy reason after cooldown window elapses.'
  );

  const clearedScenario = await runScenario({
    envOverrides: {
      CRITICAL_STATE: 'false',
      CRITICAL_ESCALATED: 'false'
    },
    comments: [{ id: 601, body: buildCriticalComment(5) }]
  });
  assertCondition(
    clearedScenario.outputs.critical_comment_action === 'cleared',
    'Expected narrative critical comment action=cleared when critical state recovers.'
  );
  assertCondition(
    clearedScenario.outputs.critical_comment_policy_reason === 'not-critical-cleared-comments',
    'Expected recovered-state clear policy reason.'
  );
  assertCondition(
    countMarkerComments(clearedScenario.comments) === 0,
    'Expected no marker comments after recovered-state clear.'
  );

  const notPresentScenario = await runScenario({
    envOverrides: {
      CRITICAL_STATE: 'false',
      CRITICAL_ESCALATED: 'false'
    },
    comments: []
  });
  assertCondition(
    notPresentScenario.outputs.critical_comment_action === 'not-present',
    'Expected not-present when recovered state has no marker comments.'
  );
  assertCondition(
    notPresentScenario.outputs.critical_comment_policy_reason === 'not-critical-no-comment-present',
    'Expected not-present recovered policy reason.'
  );

  const noEscalationScenario = await runScenario({
    envOverrides: {
      CRITICAL_STATE: 'true',
      CRITICAL_ESCALATED: 'false',
      CRITICAL_OCCURRENCES: '1'
    },
    comments: [{ id: 701, body: buildCriticalComment(1) }]
  });
  assertCondition(
    noEscalationScenario.outputs.critical_comment_action === 'cleared',
    'Expected monitoring state below threshold to clear prior critical comments.'
  );

  const invalidIssueScenario = await runScenario({
    envOverrides: {
      CHECKLIST_ISSUE_NUMBER: ''
    },
    comments: [{ id: 801, body: buildCriticalComment(2) }]
  });
  assertCondition(
    invalidIssueScenario.outputs.critical_comment_action === 'skipped-invalid-issue',
    'Expected skipped-invalid-issue when checklist issue is missing.'
  );
  assertCondition(
    invalidIssueScenario.outputs.critical_comment_policy_reason === 'invalid-checklist-issue',
    'Expected invalid-checklist policy reason for skipped reconciliation.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder narrative route critical comment fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder narrative route critical comment fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
