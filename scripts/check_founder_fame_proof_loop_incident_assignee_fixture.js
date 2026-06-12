#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Reconcile founder fame proof loop verifier incident issue';
const marker = '<!-- weekly-growth-founder-fame-proof-loop-verifier-incident -->';
const defaultWeek = '2026-W24';

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

function buildIncidentBody({ week = defaultWeek, failureCount = 0 }) {
  return `${marker}

# Growth Incident: Founder Fame Proof Loop Verifier ${week}

- Verification outcome: failure
- Failure occurrences for this week: ${failureCount}
`;
}

function createIncidentIssue({ number, state = 'open', week = defaultWeek, failureCount = 0, labels = [] }) {
  return {
    number: Number(number),
    state,
    title: `Growth Incident: Founder Fame Proof Loop Verifier ${week}`,
    body: buildIncidentBody({ week, failureCount }),
    labels: Array.isArray(labels) ? labels.slice() : []
  };
}

function normalizeIssue(issue, index) {
  return {
    number: Number(issue.number || index + 1),
    state: issue.state || 'open',
    title: String(issue.title || ''),
    body: String(issue.body || ''),
    labels: (Array.isArray(issue.labels) ? issue.labels : []).map((label) => String(label))
  };
}

function resolveBehaviorDecision(behavior, issueNumber, candidate) {
  if (!behavior) {
    return null;
  }

  if (typeof behavior === 'function') {
    return behavior({ issueNumber, candidate });
  }

  if (typeof behavior === 'object') {
    const keys = [
      `${issueNumber}:${candidate}`,
      `*:${candidate}`,
      `${issueNumber}:*`,
      '*:*'
    ];
    for (const key of keys) {
      if (Object.prototype.hasOwnProperty.call(behavior, key)) {
        return behavior[key];
      }
    }
  }

  return null;
}

function throwIfBehaviorFailure(decision, fallbackMessage) {
  if (
    decision === null ||
    decision === undefined ||
    decision === true ||
    String(decision).toLowerCase() === 'success'
  ) {
    return;
  }

  if (typeof decision === 'number' && Number.isFinite(decision)) {
    const error = new Error(fallbackMessage || `HTTP ${decision}`);
    error.status = decision;
    throw error;
  }

  if (typeof decision === 'object') {
    if (decision.ok === true) {
      return;
    }
    if (decision.status !== undefined) {
      const parsedStatus = Number(decision.status);
      const error = new Error(decision.message || fallbackMessage || `HTTP ${parsedStatus}`);
      error.status = Number.isFinite(parsedStatus) ? parsedStatus : 500;
      throw error;
    }
    return;
  }

  const maybeStatus = Number(decision);
  if (Number.isFinite(maybeStatus) && maybeStatus > 0) {
    const error = new Error(fallbackMessage || `HTTP ${maybeStatus}`);
    error.status = maybeStatus;
    throw error;
  }
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', script);

  return async function runScenario({
    issues,
    envOverrides,
    addAssigneeBehavior,
    removeAssigneeBehavior
  }) {
    const outputs = {};
    const infoMessages = [];
    const warningMessages = [];
    const issueStore = Array.isArray(issues)
      ? issues.map((issue, index) => normalizeIssue(issue, index))
      : [];
    const createdLabels = new Map();
    const addAssigneeCalls = [];
    const removeAssigneeCalls = [];

    function findIssueIndex(issueNumber) {
      return issueStore.findIndex((issue) => Number(issue.number) === Number(issueNumber));
    }

    function getIssue(issueNumber) {
      const targetIndex = findIssueIndex(issueNumber);
      assertCondition(targetIndex >= 0, `Issue #${issueNumber} not found in fixture store.`);
      return issueStore[targetIndex];
    }

    const github = {
      paginate: async () =>
        issueStore.map((issue) => ({
          ...issue,
          labels: issue.labels.map((label) => ({ name: label }))
        })),
      rest: {
        issues: {
          listForRepo: async () => ({
            data: issueStore.map((issue) => ({
              ...issue,
              labels: issue.labels.map((label) => ({ name: label }))
            }))
          }),
          getLabel: async ({ name }) => {
            const label = createdLabels.get(String(name));
            if (!label) {
              const error = new Error(`Label ${name} not found.`);
              error.status = 404;
              throw error;
            }
            return { data: { ...label } };
          },
          createLabel: async ({ name, color, description }) => {
            const label = {
              name: String(name),
              color: String(color || ''),
              description: String(description || '')
            };
            createdLabels.set(label.name, label);
            return { data: { ...label } };
          },
          create: async ({ title, body, labels }) => {
            const nextNumber =
              issueStore.reduce((max, issue) => Math.max(max, Number(issue.number) || 0), 0) + 1;
            const createdIssue = {
              number: nextNumber,
              state: 'open',
              title: String(title || ''),
              body: String(body || ''),
              labels: Array.isArray(labels) ? labels.map((label) => String(label)) : []
            };
            issueStore.push(createdIssue);
            return {
              data: {
                ...createdIssue,
                labels: createdIssue.labels.map((label) => ({ name: label }))
              }
            };
          },
          update: async ({ issue_number, title, body, state }) => {
            const issue = getIssue(issue_number);
            if (title !== undefined) {
              issue.title = String(title);
            }
            if (body !== undefined) {
              issue.body = String(body);
            }
            if (state !== undefined) {
              issue.state = String(state);
            }
            return {
              data: {
                ...issue,
                labels: issue.labels.map((label) => ({ name: label }))
              }
            };
          },
          addLabels: async ({ issue_number, labels }) => {
            const issue = getIssue(issue_number);
            for (const label of Array.isArray(labels) ? labels : []) {
              const labelName = String(label);
              if (!issue.labels.includes(labelName)) {
                issue.labels.push(labelName);
              }
            }
            return { data: issue.labels.map((label) => ({ name: label })) };
          },
          removeLabel: async ({ issue_number, name }) => {
            const issue = getIssue(issue_number);
            const targetIndex = issue.labels.findIndex((label) => label === String(name));
            if (targetIndex < 0) {
              const error = new Error(`Label ${name} not found on issue #${issue_number}.`);
              error.status = 404;
              throw error;
            }
            issue.labels.splice(targetIndex, 1);
            return { data: {} };
          },
          addAssignees: async ({ issue_number, assignees }) => {
            const candidate = String((assignees || [])[0] || '').replace(/^@+/, '');
            const issueNumber = Number(issue_number);
            addAssigneeCalls.push(`${issueNumber}:${candidate}`);
            const decision = resolveBehaviorDecision(addAssigneeBehavior, issueNumber, candidate);
            throwIfBehaviorFailure(decision, `Failed to assign @${candidate}.`);
            return { data: { assignees: [candidate] } };
          },
          removeAssignees: async ({ issue_number, assignees }) => {
            const candidate = String((assignees || [])[0] || '').replace(/^@+/, '');
            const issueNumber = Number(issue_number);
            removeAssigneeCalls.push(`${issueNumber}:${candidate}`);
            const decision = resolveBehaviorDecision(removeAssigneeBehavior, issueNumber, candidate);
            throwIfBehaviorFailure(decision, `Failed to unassign @${candidate}.`);
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
      warning: (message) => warningMessages.push(String(message)),
      setOutput: (key, value) => {
        outputs[String(key)] = String(value);
      }
    };

    const env = {
      WEEK: defaultWeek,
      CHECKLIST_ISSUE_NUMBER: '17',
      VERIFICATION_OUTCOME: 'failure',
      CHECK_PATH: '.build/founder/founder-fame-proof-loop-check-2026-W24.md',
      VERIFY_EXIT_CODE: '1',
      RUN_URL: 'https://example.local/run/current',
      CRITICAL_THRESHOLD: '3',
      CRITICAL_ASSIGNEE: 'ops-owner',
      CRITICAL_ASSIGNEES: 'fallback',
      ...(envOverrides || {})
    };

    await executor(github, context, core, { env });

    return {
      outputs,
      infoMessages,
      warningMessages,
      issues: issueStore.map((issue) => ({
        ...issue,
        labels: issue.labels.slice()
      })),
      addAssigneeCalls: addAssigneeCalls.slice(),
      removeAssigneeCalls: removeAssigneeCalls.slice()
    };
  };
}

function getIssueByNumber(issues, issueNumber) {
  return issues.find((issue) => Number(issue.number) === Number(issueNumber)) || null;
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const assignedScenario = await runScenario({
    issues: [createIncidentIssue({ number: 901, failureCount: 2, labels: ['growth-incident'] })]
  });
  const assignedIssue = getIssueByNumber(assignedScenario.issues, 901);
  assertCondition(
    assignedScenario.outputs.critical_assignee_action === 'assigned',
    'Expected critical_assignee_action=assigned when first assignee is assignable.'
  );
  assertCondition(
    assignedScenario.outputs.critical_assignee_selected === 'ops-owner',
    'Expected critical_assignee_selected to capture first successful assignee.'
  );
  assertCondition(
    assignedScenario.outputs.critical_assignee_attempts === '@ops-owner:assigned',
    'Expected first successful assignee attempt to be recorded.'
  );
  assertCondition(
    assignedScenario.addAssigneeCalls.includes('901:ops-owner'),
    'Expected addAssignees call for the primary critical assignee.'
  );
  assertCondition(
    assignedIssue && assignedIssue.labels.includes('growth-critical'),
    'Expected critical escalation to apply the growth-critical label.'
  );

  const assignFailedScenario = await runScenario({
    issues: [createIncidentIssue({ number: 902, failureCount: 2, labels: ['growth-incident'] })],
    addAssigneeBehavior: {
      '*:ops-owner': 422,
      '*:fallback': 404
    }
  });
  assertCondition(
    assignFailedScenario.outputs.critical_assignee_action === 'assign-failed',
    'Expected critical_assignee_action=assign-failed when all assignee candidates are unassignable.'
  );
  assertCondition(
    assignFailedScenario.outputs.critical_assignee_selected === '',
    'Expected no critical assignee to be selected after assign-failed outcome.'
  );
  assertCondition(
    assignFailedScenario.outputs.critical_assignee_attempts.includes(
      '@ops-owner:invalid-or-unassignable'
    ) &&
      assignFailedScenario.outputs.critical_assignee_attempts.includes(
        '@fallback:invalid-or-unassignable'
      ),
    'Expected assign-failed attempts to record invalid-or-unassignable candidate outcomes.'
  );

  const unassignedScenario = await runScenario({
    issues: [createIncidentIssue({ number: 903, failureCount: 0, labels: ['growth-incident'] })]
  });
  assertCondition(
    unassignedScenario.outputs.critical_escalated === 'false',
    'Expected critical escalation=false when failure count remains below threshold.'
  );
  assertCondition(
    unassignedScenario.outputs.critical_assignee_action === 'unassigned',
    'Expected critical_assignee_action=unassigned when configured assignees are removed successfully.'
  );
  assertCondition(
    unassignedScenario.outputs.critical_assignee_attempts.includes('@ops-owner:unassigned') &&
      unassignedScenario.outputs.critical_assignee_attempts.includes('@fallback:unassigned'),
    'Expected unassigned attempts to be recorded for all configured assignees.'
  );

  const alreadyUnassignedScenario = await runScenario({
    issues: [createIncidentIssue({ number: 904, failureCount: 0, labels: ['growth-incident'] })],
    removeAssigneeBehavior: {
      '*:ops-owner': 404,
      '*:fallback': 422
    }
  });
  assertCondition(
    alreadyUnassignedScenario.outputs.critical_assignee_action === 'already-unassigned',
    'Expected critical_assignee_action=already-unassigned when assignees are already removed.'
  );
  assertCondition(
    alreadyUnassignedScenario.outputs.critical_assignee_attempts.includes(
      '@ops-owner:already-unassigned'
    ) &&
      alreadyUnassignedScenario.outputs.critical_assignee_attempts.includes(
        '@fallback:already-unassigned'
      ),
    'Expected already-unassigned attempts to be recorded for all candidates.'
  );

  const unassignFailedScenario = await runScenario({
    issues: [createIncidentIssue({ number: 905, failureCount: 0, labels: ['growth-incident'] })],
    removeAssigneeBehavior: {
      '*:ops-owner': 500,
      '*:fallback': 404
    }
  });
  assertCondition(
    unassignFailedScenario.outputs.critical_assignee_action === 'unassign-failed',
    'Expected critical_assignee_action=unassign-failed when unassign API errors occur.'
  );
  assertCondition(
    unassignFailedScenario.outputs.critical_assignee_attempts.includes('@ops-owner:error-500'),
    'Expected unassign-failed attempts to preserve hard API error details.'
  );

  const duplicateSanityScenario = await runScenario({
    issues: [
      createIncidentIssue({ number: 940, failureCount: 2, labels: ['growth-incident'] }),
      createIncidentIssue({ number: 939, failureCount: 1, labels: ['growth-incident'] })
    ],
    removeAssigneeBehavior: {
      '939:ops-owner': 500,
      '939:fallback': 422
    }
  });
  const duplicateIssue = getIssueByNumber(duplicateSanityScenario.issues, 939);
  assertCondition(
    duplicateSanityScenario.outputs.critical_assignee_action === 'assigned',
    'Expected duplicate unassign attempts with updateAction=false not to override assigned status.'
  );
  assertCondition(
    duplicateSanityScenario.outputs.critical_assignee_attempts === '@ops-owner:assigned',
    'Expected duplicate cleanup to preserve primary issue assignment attempts output.'
  );
  assertCondition(
    duplicateIssue && duplicateIssue.state === 'closed',
    'Expected duplicate incident issue to be closed during reconciliation.'
  );
  assertCondition(
    duplicateSanityScenario.removeAssigneeCalls.includes('939:ops-owner'),
    'Expected duplicate issue cleanup to attempt assignee removal.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder fame proof-loop incident assignee fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder fame proof-loop incident assignee fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
