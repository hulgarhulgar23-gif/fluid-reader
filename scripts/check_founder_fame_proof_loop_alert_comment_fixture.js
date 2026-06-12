#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const marker = '<!-- weekly-growth-founder-fame-proof-loop-verifier-failure -->';

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

function buildAlertComment(failureCount) {
  return `${marker}

⚠️ Founder fame proof loop strict verification failed in the latest Weekly Growth Review run.

- Failure count this week: \`${failureCount}\`
- Verification report: \`.build/founder/founder-fame-proof-loop-check-2026-W24.md\`
- Verifier exit code: \`1\`
- Workflow run: https://example.local/run/old

Action: review the proof-loop artifact, resolve failed checks, and rerun review workflow.
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
      VERIFICATION_OUTCOME: 'failure',
      CHECK_PATH: '.build/founder/founder-fame-proof-loop-check-2026-W24.md',
      VERIFY_EXIT_CODE: '1',
      ALERT_COMMENT_COOLDOWN_HOURS: '24',
      ALERT_COMMENT_MIN_FAILURE_DELTA: '2',
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
    'Reconcile founder fame proof loop verification alert comment'
  );
  const runScenario = createRunner(script);

  const createdScenario = await runScenario({ comments: [] });
  assertCondition(
    createdScenario.outputs.alert_comment_action === 'created',
    'Expected founder alert action=created when no prior marker comment exists.'
  );
  assertCondition(
    createdScenario.outputs.alert_comment_policy_reason === 'created-no-existing-comment',
    'Expected founder alert created policy reason when no prior marker comment exists.'
  );
  assertCondition(
    createdScenario.outputs.alert_comment_cooldown_hours === '24' &&
      createdScenario.outputs.alert_comment_min_failure_delta === '2',
    'Expected founder alert cooldown/min-delta outputs to reflect parsed policy inputs.'
  );
  assertCondition(
    createdScenario.outputs.alert_comment_failure_delta === '1',
    'Expected founder alert failure delta to equal first failure count on create.'
  );
  assertCondition(
    countMarkerComments(createdScenario.comments) === 1,
    'Expected one founder alert marker comment to be created.'
  );

  const cooldownSkipScenario = await runScenario({
    envOverrides: {
      ALERT_COMMENT_MIN_FAILURE_DELTA: '2',
      ALERT_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 300,
        body: buildAlertComment(1),
        created_at: isoTimestampHoursAgo(1),
        updated_at: isoTimestampHoursAgo(1)
      },
      {
        id: 301,
        body: buildAlertComment(0),
        created_at: isoTimestampHoursAgo(8),
        updated_at: isoTimestampHoursAgo(8)
      }
    ]
  });
  const cooldownSkipPrimary = cooldownSkipScenario.comments.find((comment) => comment.id === 300);
  assertCondition(
    cooldownSkipScenario.outputs.alert_comment_action === 'cooldown-delta-skip',
    'Expected founder alert cooldown-delta-skip when within cooldown and failure delta is below threshold.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.alert_comment_cooldown_active === 'true',
    'Expected founder alert cooldown flag true when update is skipped inside cooldown window.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.alert_comment_policy_reason ===
      'within-cooldown-and-delta-below-threshold',
    'Expected founder alert cooldown skip policy reason.'
  );
  assertCondition(
    cooldownSkipScenario.outputs.alert_comment_failure_delta === '1',
    'Expected founder alert failure delta to be computed from existing comment failure count.'
  );
  assertCondition(
    countMarkerComments(cooldownSkipScenario.comments) === 1,
    'Expected duplicate founder alert marker comments to collapse to one during cooldown skip.'
  );
  assertCondition(
    cooldownSkipPrimary &&
      String(cooldownSkipPrimary.body || '').includes('- Failure count this week: `1`'),
    'Expected founder alert primary comment body to remain unchanged when cooldown skip applies.'
  );

  const cooldownUpdateScenario = await runScenario({
    envOverrides: {
      ALERT_COMMENT_MIN_FAILURE_DELTA: '1',
      ALERT_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 400,
        body: buildAlertComment(1),
        created_at: isoTimestampHoursAgo(2),
        updated_at: isoTimestampHoursAgo(2)
      }
    ]
  });
  const cooldownUpdated = cooldownUpdateScenario.comments.find((comment) => comment.id === 400);
  assertCondition(
    cooldownUpdateScenario.outputs.alert_comment_action === 'updated',
    'Expected founder alert action=updated when failure delta meets threshold inside cooldown.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.alert_comment_policy_reason ===
      'updated-within-cooldown-delta-threshold-met',
    'Expected founder alert within-cooldown update policy reason when failure delta threshold is met.'
  );
  assertCondition(
    cooldownUpdateScenario.outputs.alert_comment_failure_delta === '1',
    'Expected founder alert failure delta to capture increment over previous comment count.'
  );
  assertCondition(
    cooldownUpdated &&
      String(cooldownUpdated.body || '').includes('- Failure count this week: `2`'),
    'Expected founder alert primary comment body to refresh with new failure count after update.'
  );

  const cooldownExpiredScenario = await runScenario({
    envOverrides: {
      ALERT_COMMENT_MIN_FAILURE_DELTA: '2',
      ALERT_COMMENT_COOLDOWN_HOURS: '24'
    },
    comments: [
      {
        id: 500,
        body: buildAlertComment(2),
        created_at: isoTimestampHoursAgo(30),
        updated_at: isoTimestampHoursAgo(30)
      }
    ]
  });
  const cooldownExpiredUpdated = cooldownExpiredScenario.comments.find(
    (comment) => comment.id === 500
  );
  assertCondition(
    cooldownExpiredScenario.outputs.alert_comment_action === 'updated',
    'Expected founder alert action=updated when cooldown window has expired.'
  );
  assertCondition(
    cooldownExpiredScenario.outputs.alert_comment_policy_reason === 'updated-cooldown-expired',
    'Expected founder alert cooldown-expired policy reason outside cooldown window.'
  );
  assertCondition(
    cooldownExpiredScenario.outputs.alert_comment_failure_delta === '1',
    'Expected founder alert failure delta to remain available when cooldown has expired.'
  );
  assertCondition(
    cooldownExpiredUpdated &&
      String(cooldownExpiredUpdated.body || '').includes('- Failure count this week: `3`'),
    'Expected founder alert updated comment body after cooldown expiry.'
  );

  const clearedScenario = await runScenario({
    envOverrides: {
      VERIFICATION_OUTCOME: 'success'
    },
    comments: [
      {
        id: 600,
        body: buildAlertComment(3),
        created_at: isoTimestampHoursAgo(1),
        updated_at: isoTimestampHoursAgo(1)
      }
    ]
  });
  assertCondition(
    clearedScenario.outputs.alert_comment_action === 'cleared',
    'Expected founder alert marker comments to be cleared when verification passes.'
  );
  assertCondition(
    clearedScenario.outputs.alert_comment_policy_reason === 'verification-passed-cleared-comments',
    'Expected founder alert cleared policy reason when stale comments are deleted.'
  );
  assertCondition(
    countMarkerComments(clearedScenario.comments) === 0,
    'Expected founder alert marker comments to be fully removed after verification pass.'
  );

  const notPresentScenario = await runScenario({
    envOverrides: {
      VERIFICATION_OUTCOME: 'success'
    },
    comments: []
  });
  assertCondition(
    notPresentScenario.outputs.alert_comment_action === 'not-present',
    'Expected founder alert action=not-present when no stale comments exist after verification pass.'
  );
  assertCondition(
    notPresentScenario.outputs.alert_comment_policy_reason ===
      'verification-passed-no-comment-present',
    'Expected founder alert not-present policy reason when no marker comments exist.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder proof-loop alert-comment fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder proof-loop alert-comment fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
