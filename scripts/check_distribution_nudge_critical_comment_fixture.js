#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const marker = '<!-- weekly-growth-distribution-nudge-verifier-critical -->';

function leadingSpaces(value) {
  const match = String(value || '').match(/^(\s*)/);
  return match ? match[1].length : 0;
}

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function extractStepScript(filePath, stepName) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const stepLineIndex = lines.findIndex((line) => line.includes(`- name: ${stepName}`));
  assertCondition(stepLineIndex >= 0, `Could not find workflow step: ${stepName}`);

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

  assertCondition(scriptLineIndex >= 0, `Could not find script block for step: ${stepName}`);

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
  assertCondition(nonEmptyLines.length > 0, `Workflow step script is empty: ${stepName}`);
  const minimumIndent = Math.min(...nonEmptyLines.map((line) => leadingSpaces(line)));
  return blockLines.map((line) => (line.trim() === '' ? '' : line.slice(minimumIndent))).join('\n');
}

function isoTimestampHoursAgo(hoursAgo) {
  return new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString();
}

function buildCriticalComment(failureCount) {
  return `${marker}

## Distribution Nudge Verifier Critical Escalation

- Status: active
- Failure count this week: ${failureCount}
- Critical threshold: 3
- Incident issue: #98
- Incident owner candidates: @ops-owner, @fallback
- Incident owner: @ops-owner
- Incident owner attempts: ops-owner:assigned
- Incident owner action: assigned
- Review run: https://example.local/run/old
- Action: Prioritize incident remediation before next publish window.
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
    let nextCommentId = currentComments.reduce((max, comment) => Math.max(max, Number(comment.id) || 0), 0) + 1;

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
      VERIFICATION_OUTCOME: 'failure',
      INCIDENT_ISSUE_NUMBER: '98',
      FAILURE_COUNT: '5',
      CRITICAL_THRESHOLD: '3',
      CRITICAL_ESCALATED: 'true',
      CRITICAL_ASSIGNEE: 'ops-owner',
      CRITICAL_ASSIGNEE_CANDIDATES: 'ops-owner,fallback',
      CRITICAL_ASSIGNEE_ATTEMPTS: 'ops-owner:assigned',
      CRITICAL_ASSIGNEE_ACTION: 'assigned',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24',
      CRITICAL_COMMENT_MIN_FAILURE_DELTA: '2',
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
  const script = extractStepScript(
    workflowPath,
    'Reconcile distribution nudge critical escalation comment'
  );
  const runScenario = createRunner(script);

  const createdScenario = await runScenario({ comments: [] });
  assertCondition(
    createdScenario.outputs.critical_comment_action === 'created',
    'Expected critical comment action=created when no prior marker comment exists.'
  );
  assertCondition(
    createdScenario.outputs.critical_comment_policy_reason === 'created-no-existing-comment',
    'Expected created policy reason when no prior marker comment exists.'
  );
  assertCondition(
    createdScenario.outputs.critical_comment_cooldown_hours === '24' &&
      createdScenario.outputs.critical_comment_min_failure_delta === '2',
    'Expected cooldown/min-delta outputs to reflect parsed policy inputs.'
  );
  assertCondition(
    createdScenario.outputs.critical_comment_failure_delta === '5',
    'Expected failure delta to equal current failure count on create.'
  );
  assertCondition(
    countMarkerComments(createdScenario.comments) === 1,
    'Expected one critical marker comment to be created.'
  );

  const cooldownSkipScenario = await runScenario({
    envOverrides: {
      FAILURE_COUNT: '6',
      CRITICAL_COMMENT_MIN_FAILURE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 300,
        body: buildCriticalComment(5),
        created_at: isoTimestampHoursAgo(1),
        updated_at: isoTimestampHoursAgo(1)
      },
      {
        id: 301,
        body: buildCriticalComment(4),
        created_at: isoTimestampHoursAgo(8),
        updated_at: isoTimestampHoursAgo(8)
      }
    ]
  });
  const cooldownSkipPrimary = cooldownSkipScenario.comments.find((comment) => comment.id === 300);
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_action === 'cooldown-delta-skip',
    'Expected cooldown-delta-skip action when within cooldown and failure delta is below threshold.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_cooldown_active === 'true',
    'Expected cooldown flag true when update is skipped inside cooldown window.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_policy_reason === 'within-cooldown-and-delta-below-threshold',
    'Expected cooldown skip policy reason.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.critical_comment_failure_delta === '1',
    'Expected failure delta to be computed from existing comment failure count.'
  );
  assertCondition(
    countMarkerComments(cooldownSkipScenario.comments) === 1,
    'Expected duplicate critical marker comments to collapse to one during cooldown skip.'
  );
  assertCondition(
    cooldownSkipPrimary &&
      String(cooldownSkipPrimary.body || '').includes('- Failure count this week: 5'),
    'Expected primary critical comment body to remain unchanged when cooldown skip is applied.'
  );

  const cooldownUpdateScenario = await runScenario({
    envOverrides: {
      FAILURE_COUNT: '8',
      CRITICAL_COMMENT_MIN_FAILURE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 400,
        body: buildCriticalComment(5),
        created_at: isoTimestampHoursAgo(2),
        updated_at: isoTimestampHoursAgo(2)
      }
    ]
  });
  const cooldownUpdated = cooldownUpdateScenario.comments.find((comment) => comment.id === 400);
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_action === 'updated',
    'Expected action=updated when failure delta reaches threshold inside cooldown.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_policy_reason ===
      'updated-within-cooldown-delta-threshold-met',
    'Expected within-cooldown update policy reason when failure delta threshold is met.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.critical_comment_failure_delta === '3',
    'Expected failure delta to capture increase over previous comment count.'
  );
  assertCondition(
    cooldownUpdated && String(cooldownUpdated.body || '').includes('- Failure count this week: 8'),
    'Expected primary critical comment body to refresh with new failure count after update.'
  );

  const cooldownExpiredScenario = await runScenario({
    envOverrides: {
      FAILURE_COUNT: '9',
      CRITICAL_COMMENT_MIN_FAILURE_DELTA: '2',
      CRITICAL_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 500,
        body: buildCriticalComment(8),
        created_at: isoTimestampHoursAgo(30),
        updated_at: isoTimestampHoursAgo(30)
      }
    ]
  });
  const cooldownExpiredUpdated = cooldownExpiredScenario.comments.find(
    (comment) => comment.id === 500
  );
  assertCondition(
    cooldownExpiredScenario.outputs.critical_comment_action === 'updated',
    'Expected action=updated when cooldown window has expired.'
  );
  assertCondition(
    cooldownExpiredScenario.outputs.critical_comment_policy_reason === 'updated-cooldown-expired',
    'Expected cooldown-expired policy reason outside cooldown window.'
  );
  assertCondition(
    cooldownExpiredScenario.outputs.critical_comment_failure_delta === '1',
    'Expected failure delta to remain available when cooldown has expired.'
  );
  assertCondition(
    cooldownExpiredUpdated &&
      String(cooldownExpiredUpdated.body || '').includes('- Failure count this week: 9'),
    'Expected updated critical comment body after cooldown expiry.'
  );

  const clearedScenario = await runScenario({
    envOverrides: {
      VERIFICATION_OUTCOME: 'success'
    },
    comments: [
      {
        id: 600,
        body: buildCriticalComment(9),
        created_at: isoTimestampHoursAgo(1),
        updated_at: isoTimestampHoursAgo(1)
      }
    ]
  });
  assertCondition(
    clearedScenario.outputs.critical_comment_action === 'cleared',
    'Expected stale critical comments to be cleared when escalation is no longer required.'
  );
  assertCondition(
    clearedScenario.outputs.critical_comment_policy_reason === 'not-escalated-cleared-comments',
    'Expected cleared policy reason when stale marker comments are deleted.'
  );
  assertCondition(
    countMarkerComments(clearedScenario.comments) === 0,
    'Expected critical marker comments to be fully removed after de-escalation.'
  );

  const notPresentScenario = await runScenario({
    envOverrides: {
      VERIFICATION_OUTCOME: 'success'
    },
    comments: []
  });
  assertCondition(
    notPresentScenario.outputs.critical_comment_action === 'not-present',
    'Expected action=not-present when no stale comments exist after de-escalation.'
  );
  assertCondition(
    notPresentScenario.outputs.critical_comment_policy_reason ===
      'not-escalated-no-comment-present',
    'Expected not-present policy reason when no marker comments are available to clear.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Distribution nudge critical-comment fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Distribution nudge critical-comment fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
