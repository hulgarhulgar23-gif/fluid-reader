#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Reconcile founder narrative route owner queue comment';
const marker = '<!-- weekly-growth-founder-narrative-route-owner-queue -->';
const incidentSyncStartMarker = '<!-- weekly-growth-founder-narrative-route-owner-sync-start -->';
const incidentSyncEndMarker = '<!-- weekly-growth-founder-narrative-route-owner-sync-end -->';
const checklistQueueStartMarker = '<!-- weekly-growth-founder-narrative-route-owner-queue-start -->';
const checklistQueueEndMarker = '<!-- weekly-growth-founder-narrative-route-owner-queue-end -->';
const defaultOwner = '@ops-owner';
const defaultRouteControlRecommendation = 'Run Route Recovery and re-lock winner before next publish';

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
    if (index > stepLineIndex + 1 && /^\s*-\s+name:/.test(line)) break;
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
    if (indent <= scriptIndent) break;
    blockLines.push(line);
  }

  const nonEmptyLines = blockLines.filter((line) => line.trim() !== '');
  assertCondition(nonEmptyLines.length > 0, `Workflow step script is empty: ${targetStepName}`);
  const minimumIndent = Math.min(...nonEmptyLines.map((line) => leadingSpaces(line)));
  return blockLines.map((line) => (line.trim() === '' ? '' : line.slice(minimumIndent))).join('\n');
}

function buildOwnerTaskSpecs({
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation
} = {}) {
  return [
    {
      key: 'route-standup',
      label: `${owner} run Route Recovery standup and lock winner + lane shift decision.`
    },
    {
      key: 'route-control-exec',
      label: `${owner} execute control recommendation: ${routeControlRecommendation}.`
    },
    {
      key: 'route-proof-sync',
      label: `${owner} publish route alignment proof update in narrative lab and sprint issue.`
    },
    {
      key: 'route-checkpoint-update',
      label: `${owner} post checklist progress update with blockers and next checkpoint.`
    }
  ];
}

function buildQueueTaskLines({
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation,
  checkedTaskKeys = []
} = {}) {
  const checkedSet = new Set(
    (Array.isArray(checkedTaskKeys) ? checkedTaskKeys : []).map((value) => String(value))
  );
  return buildOwnerTaskSpecs({ owner, routeControlRecommendation })
    .map((task, index) => `${index + 1}. [${checkedSet.has(task.key) ? 'x' : ' '}] ${task.label}`)
    .join('\n');
}

function buildChecklistTaskLines({
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation,
  checkedTaskKeys = []
} = {}) {
  const checkedSet = new Set(
    (Array.isArray(checkedTaskKeys) ? checkedTaskKeys : []).map((value) => String(value))
  );
  return buildOwnerTaskSpecs({ owner, routeControlRecommendation })
    .map(
      (task) =>
        `- [${checkedSet.has(task.key) ? 'x' : ' '}] \`${task.key}\`: ${task.label}`
    )
    .join('\n');
}

function buildOwnerQueueComment({
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation,
  checkedTaskKeys = []
} = {}) {
  return `${marker}

## Founder Narrative Route Owner Queue (Critical)

- Owner selected: ${owner}
- Route mode: Route Recovery
- Route lane status: Critical

### Immediate owner tasks

${buildQueueTaskLines({
  owner,
  routeControlRecommendation,
  checkedTaskKeys
})}
`;
}

function buildChecklistIssueBody({
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation,
  withOwnerQueueBlock = false,
  checkedTaskKeys = []
} = {}) {
  const base = `# Monday Publish Checklist: 2026-W24

## Narrative Route Controls

- Narrative route preferred variant: proof
`;

  if (!withOwnerQueueBlock) {
    return `${base}\n`;
  }

  return `${base}
${checklistQueueStartMarker}

## Founder Narrative Route Owner Queue (Auto-Managed)

- Source week: 2026-W24
- Critical trigger: route-recovery+critical-lane
- Critical occurrences this week: 2
- Critical threshold: 2
- Incident issue: #98
- Owner selected: ${owner}
- Owner candidates: ${owner}, @fallback
- Assignment action: assigned
- Assignment attempts: @ops-owner:assigned
- Queue comment marker: ${marker}
- Review run: https://example.local/run/current

${buildChecklistTaskLines({
  owner,
  routeControlRecommendation,
  checkedTaskKeys
})}

${checklistQueueEndMarker}
`;
}

function buildIncidentIssueBody({
  withSyncBlock = false,
  owner = defaultOwner,
  routeControlRecommendation = defaultRouteControlRecommendation,
  checkedTaskKeys = []
} = {}) {
  const base = `<!-- weekly-growth-founder-narrative-route-incident -->

# Growth Incident: Founder Narrative Route Control 2026-W24

- Critical trigger: route-recovery+critical-lane
- Critical occurrences for this week: 2
- Critical threshold: 2
- Critical escalation status: active
- Route mode: Route Recovery
`;
  if (!withSyncBlock) {
    return `${base}\n`;
  }
  return `${base}
${incidentSyncStartMarker}

## Founder Narrative Route Owner Execution Mirror

- Checklist issue: #17
- Owner selected: ${owner}

${buildQueueTaskLines({
  owner,
  routeControlRecommendation,
  checkedTaskKeys
})}

${incidentSyncEndMarker}
`;
}

function countMarkerComments(comments) {
  return comments.filter((comment) => String(comment.body || '').includes(marker)).length;
}

function normalizeIssue(issue, index) {
  return {
    number: Number(issue.number || index + 1),
    state: String(issue.state || 'open'),
    title: String(issue.title || ''),
    body: String(issue.body || ''),
    labels: (Array.isArray(issue.labels) ? issue.labels : []).map((label) => String(label))
  };
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', script);

  return async function runScenario({ envOverrides, comments, issues }) {
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
    const issueStore = Array.isArray(issues)
      ? issues.map((issue, index) => normalizeIssue(issue, index))
      : [
          normalizeIssue(
            {
              number: 17,
              title: 'Monday Publish Checklist 2026-W24',
              body: buildChecklistIssueBody(),
              labels: ['growth-checklist']
            },
            0
          ),
          normalizeIssue(
            {
              number: 98,
              title: 'Growth Incident: Founder Narrative Route Control 2026-W24',
              body: buildIncidentIssueBody(),
              labels: ['growth-incident', 'growth-critical']
            },
            1
          )
        ];

    function getIssue(issueNumber) {
      const issue = issueStore.find((entry) => Number(entry.number) === Number(issueNumber));
      assertCondition(issue, `Issue #${issueNumber} not found in fixture store.`);
      return issue;
    }

    const github = {
      paginate: async (_method, params = {}) => {
        if (params.issue_number) {
          return currentComments.map((comment) => ({ ...comment }));
        }
        return issueStore.map((issue) => ({
          ...issue,
          labels: issue.labels.map((label) => ({ name: label }))
        }));
      },
      rest: {
        issues: {
          get: async ({ issue_number }) => {
            const issue = getIssue(issue_number);
            return { data: { ...issue, labels: issue.labels.map((label) => ({ name: label })) } };
          },
          update: async ({ issue_number, body, title, state }) => {
            const issue = getIssue(issue_number);
            if (body !== undefined) issue.body = String(body);
            if (title !== undefined) issue.title = String(title);
            if (state !== undefined) issue.state = String(state);
            return { data: { ...issue, labels: issue.labels.map((label) => ({ name: label })) } };
          },
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
            const targetIndex = currentComments.findIndex((comment) => String(comment.id) === String(comment_id));
            assertCondition(targetIndex >= 0, `Cannot update missing comment #${comment_id}.`);
            currentComments[targetIndex] = {
              ...currentComments[targetIndex],
              body: String(body || ''),
              updated_at: new Date().toISOString()
            };
            return { data: { ...currentComments[targetIndex] } };
          },
          deleteComment: async ({ comment_id }) => {
            const targetIndex = currentComments.findIndex((comment) => String(comment.id) === String(comment_id));
            if (targetIndex >= 0) currentComments.splice(targetIndex, 1);
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
      warning: (message) => infoMessages.push(`WARN: ${String(message)}`),
      setOutput: (key, value) => {
        outputs[String(key)] = String(value);
      }
    };

    const env = {
      CHECKLIST_ISSUE_NUMBER: '17',
      SOURCE_WEEK: '2026-W24',
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
      ROUTE_CONTROL_RECOMMENDATION: defaultRouteControlRecommendation,
      RUN_URL: 'https://example.local/run/current',
      ...(envOverrides || {})
    };

    await executor(github, context, core, { env });

    return {
      outputs,
      infoMessages,
      comments: currentComments.map((comment) => ({ ...comment })),
      issues: issueStore.map((issue) => ({
        ...issue,
        labels: issue.labels.slice()
      }))
    };
  };
}

function getIssueByNumber(issues, issueNumber) {
  return issues.find((issue) => Number(issue.number) === Number(issueNumber)) || null;
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const createdScenario = await runScenario({ comments: [] });
  const createdChecklistIssue = getIssueByNumber(createdScenario.issues, 17);
  const createdIncidentIssue = getIssueByNumber(createdScenario.issues, 98);
  const createdQueueComment = createdScenario.comments.find((comment) =>
    String(comment.body || '').includes(marker)
  );
  assertCondition(
    createdScenario.outputs.owner_queue_status === 'active' &&
      createdScenario.outputs.owner_queue_comment_action === 'created',
    'Expected owner queue comment to be created when narrative route critical escalation is active.'
  );
  assertCondition(
    createdScenario.outputs.owner_queue_checklist_block_action === 'upserted',
    'Expected checklist owner queue block to upsert when escalation activates.'
  );
  assertCondition(
    createdScenario.outputs.owner_queue_completed_tasks === '0' &&
      createdScenario.outputs.owner_queue_open_tasks === '4',
    'Expected created scenario to report zero completed and four open owner tasks.'
  );
  assertCondition(
    createdScenario.outputs.incident_owner_sync_action === 'upserted' &&
      createdScenario.outputs.incident_owner_sync_status === 'active',
    'Expected incident owner sync block to upsert when critical owner queue is active.'
  );
  assertCondition(
    createdScenario.outputs.owner_queue_owner === '@ops-owner',
    'Expected selected owner output to use primary assigned owner.'
  );
  assertCondition(
    countMarkerComments(createdScenario.comments) === 1,
    'Expected exactly one owner queue marker comment after create scenario.'
  );
  assertCondition(
    createdChecklistIssue &&
      String(createdChecklistIssue.body || '').includes(checklistQueueStartMarker) &&
      String(createdChecklistIssue.body || '').includes(checklistQueueEndMarker),
    'Expected checklist issue body to include owner queue checklist block after create scenario.'
  );
  assertCondition(
    createdQueueComment && String(createdQueueComment.body || '').includes('1. [ ]'),
    'Expected created owner queue comment to include unchecked owner tasks.'
  );
  assertCondition(
    createdIncidentIssue &&
      String(createdIncidentIssue.body || '').includes(incidentSyncStartMarker) &&
      String(createdIncidentIssue.body || '').includes('- Checklist issue: #17') &&
      String(createdIncidentIssue.body || '').includes('1. [ ]'),
    'Expected incident issue body to include owner sync block with checklist issue reference.'
  );

  const updatedScenario = await runScenario({
    comments: [
      { id: 100, body: buildOwnerQueueComment({ owner: '@ops-owner' }) },
      { id: 101, body: buildOwnerQueueComment({ owner: '@fallback' }) }
    ],
    issues: [
      {
        number: 17,
        title: 'Monday Publish Checklist 2026-W24',
        body: buildChecklistIssueBody({
          withOwnerQueueBlock: true,
          checkedTaskKeys: ['route-control-exec']
        }),
        labels: ['growth-checklist']
      },
      {
        number: 98,
        title: 'Growth Incident: Founder Narrative Route Control 2026-W24',
        body: buildIncidentIssueBody(),
        labels: ['growth-incident', 'growth-critical']
      }
    ]
  });
  const updatedQueueComment = updatedScenario.comments.find((comment) =>
    String(comment.body || '').includes(marker)
  );
  const updatedIncidentIssue = getIssueByNumber(updatedScenario.issues, 98);
  const updatedChecklistIssue = getIssueByNumber(updatedScenario.issues, 17);
  assertCondition(
    updatedScenario.outputs.owner_queue_comment_action === 'updated',
    'Expected owner queue comment update when an active marker comment already exists.'
  );
  assertCondition(
    updatedScenario.outputs.owner_queue_duplicate_comments_cleared === '1',
    'Expected duplicate owner queue comments to be cleared during reconciliation.'
  );
  assertCondition(
    updatedScenario.outputs.incident_owner_sync_action === 'upserted',
    'Expected incident owner sync block to upsert during owner queue update.'
  );
  assertCondition(
    updatedScenario.outputs.owner_queue_checklist_block_action === 'upserted',
    'Expected checklist owner queue block to refresh when active state reconciles.'
  );
  assertCondition(
    updatedScenario.outputs.owner_queue_completed_tasks === '1' &&
      updatedScenario.outputs.owner_queue_open_tasks === '3',
    'Expected checked checklist task to propagate to owner queue task counts.'
  );
  assertCondition(
    countMarkerComments(updatedScenario.comments) === 1,
    'Expected dedupe to keep only one owner queue marker comment.'
  );
  assertCondition(
    updatedQueueComment && String(updatedQueueComment.body || '').includes('2. [x]'),
    'Expected owner queue comment to mirror checked route-control task state.'
  );
  assertCondition(
    updatedIncidentIssue && String(updatedIncidentIssue.body || '').includes('2. [x]'),
    'Expected incident sync block to mirror checked route-control task state.'
  );
  assertCondition(
    updatedChecklistIssue &&
      String(updatedChecklistIssue.body || '').includes('- [x] `route-control-exec`'),
    'Expected checklist owner queue block to persist checked route-control task state.'
  );

  const clearedScenario = await runScenario({
    envOverrides: {
      CRITICAL_STATE: 'false',
      CRITICAL_ESCALATED: 'false'
    },
    comments: [{ id: 200, body: buildOwnerQueueComment({ owner: '@ops-owner' }) }],
    issues: [
      {
        number: 17,
        title: 'Monday Publish Checklist 2026-W24',
        body: buildChecklistIssueBody({
          withOwnerQueueBlock: true,
          checkedTaskKeys: ['route-standup', 'route-control-exec']
        }),
        labels: ['growth-checklist']
      },
      {
        number: 98,
        title: 'Growth Incident: Founder Narrative Route Control 2026-W24',
        body: buildIncidentIssueBody({
          withSyncBlock: true,
          checkedTaskKeys: ['route-standup', 'route-control-exec']
        }),
        labels: ['growth-incident']
      }
    ]
  });
  const clearedChecklistIssue = getIssueByNumber(clearedScenario.issues, 17);
  const clearedIncidentIssue = getIssueByNumber(clearedScenario.issues, 98);
  assertCondition(
    clearedScenario.outputs.owner_queue_status === 'cleared' &&
      clearedScenario.outputs.owner_queue_comment_action === 'deleted',
    'Expected owner queue comment to clear when critical state is recovered.'
  );
  assertCondition(
    clearedScenario.outputs.owner_queue_checklist_block_action === 'cleared',
    'Expected checklist owner queue block to clear when critical state is recovered.'
  );
  assertCondition(
    clearedScenario.outputs.owner_queue_completed_tasks === '0' &&
      clearedScenario.outputs.owner_queue_open_tasks === '0',
    'Expected recovered scenario to report zero active owner tasks.'
  );
  assertCondition(
    clearedScenario.outputs.incident_owner_sync_action === 'cleared' &&
      clearedScenario.outputs.incident_owner_sync_status === 'cleared',
    'Expected incident owner sync block to clear when narrative route pressure recovers.'
  );
  assertCondition(
    countMarkerComments(clearedScenario.comments) === 0,
    'Expected no owner queue marker comments after clear scenario.'
  );
  assertCondition(
    clearedChecklistIssue &&
      !String(clearedChecklistIssue.body || '').includes(checklistQueueStartMarker),
    'Expected checklist owner queue block to be removed after recovery.'
  );
  assertCondition(
    clearedIncidentIssue && !String(clearedIncidentIssue.body || '').includes(incidentSyncStartMarker),
    'Expected incident issue owner sync block to be removed after recovery.'
  );

  const notPresentScenario = await runScenario({
    envOverrides: {
      CRITICAL_STATE: 'false',
      CRITICAL_ESCALATED: 'false'
    },
    comments: []
  });
  assertCondition(
    notPresentScenario.outputs.owner_queue_status === 'not-needed' &&
      notPresentScenario.outputs.owner_queue_comment_action === 'not-present',
    'Expected not-needed/not-present when no owner queue comment exists in recovered state.'
  );
  assertCondition(
    notPresentScenario.outputs.owner_queue_checklist_block_action === 'not-present',
    'Expected not-present checklist block action when no checklist owner queue block exists.'
  );
  assertCondition(
    notPresentScenario.outputs.owner_queue_completed_tasks === '0' &&
      notPresentScenario.outputs.owner_queue_open_tasks === '0',
    'Expected not-needed scenario to report zero owner tasks.'
  );
  assertCondition(
    notPresentScenario.outputs.incident_owner_sync_action === 'not-present',
    'Expected incident sync action not-present when recovery state has no sync block.'
  );

  const missingIncidentScenario = await runScenario({
    envOverrides: {
      INCIDENT_ISSUE_NUMBER: ''
    },
    comments: []
  });
  assertCondition(
    missingIncidentScenario.outputs.owner_queue_status === 'active' &&
      missingIncidentScenario.outputs.incident_owner_sync_action === 'skipped-invalid-incident-issue',
    'Expected missing incident issue number to skip owner sync while owner queue comment still upserts.'
  );
  assertCondition(
    missingIncidentScenario.outputs.owner_queue_checklist_block_action === 'upserted' &&
      missingIncidentScenario.outputs.owner_queue_completed_tasks === '0' &&
      missingIncidentScenario.outputs.owner_queue_open_tasks === '4',
    'Expected missing incident scenario to still maintain checklist owner queue state outputs.'
  );

  const invalidIssueScenario = await runScenario({
    envOverrides: {
      CHECKLIST_ISSUE_NUMBER: ''
    },
    comments: [{ id: 300, body: buildOwnerQueueComment({ owner: '@ops-owner' }) }]
  });
  assertCondition(
    invalidIssueScenario.outputs.owner_queue_status === 'skipped-invalid-issue' &&
      invalidIssueScenario.outputs.owner_queue_comment_action === 'skipped-invalid-issue',
    'Expected invalid checklist issue scenario to skip owner queue reconciliation.'
  );
  assertCondition(
    invalidIssueScenario.outputs.owner_queue_checklist_block_action === 'none' &&
      invalidIssueScenario.outputs.owner_queue_completed_tasks === '0' &&
      invalidIssueScenario.outputs.owner_queue_open_tasks === '0',
    'Expected invalid checklist issue scenario to preserve default owner queue block outputs.'
  );
  assertCondition(
    invalidIssueScenario.outputs.incident_owner_sync_action === 'not-attempted',
    'Expected invalid checklist issue scenario to skip incident owner sync attempts.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder narrative route owner queue fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder narrative route owner queue fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
