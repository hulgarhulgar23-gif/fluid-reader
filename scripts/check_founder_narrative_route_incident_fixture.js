#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Reconcile founder narrative route incident issue';
const marker = '<!-- weekly-growth-founder-narrative-route-incident -->';
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

function buildIncidentBody({
  week = defaultWeek,
  criticalTrigger = 'route-recovery+critical-lane',
  criticalOccurrences = 1
}) {
  return `${marker}

# Growth Incident: Founder Narrative Route Control ${week}

- Critical trigger: ${criticalTrigger}
- Critical occurrences for this week: ${criticalOccurrences}
`;
}

function createIncidentIssue({
  number,
  state = 'open',
  week = defaultWeek,
  criticalTrigger = 'route-recovery+critical-lane',
  criticalOccurrences = 1,
  labels = []
}) {
  return {
    number: Number(number),
    state,
    title: `Growth Incident: Founder Narrative Route Control ${week}`,
    body: buildIncidentBody({
      week,
      criticalTrigger,
      criticalOccurrences
    }),
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
    const keys = [`${issueNumber}:${candidate}`, `*:${candidate}`, `${issueNumber}:*`, '*:*'];
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
    if (decision.ok === true) return;
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
      ROUTE_MODE: 'Route Recovery',
      ROUTE_ALIGNMENT_TARGET: 'Aligned by Day 1',
      ROUTE_LANE_STATUS: 'Critical',
      ROUTE_GUARDRAIL: 'Keep every route update tied to one measurable proof artifact.',
      ROUTE_CONTROL_RECOMMENDATION: 'Run Route Recovery and re-lock winner before next publish.',
      ROUTE_RECOMMENDATION: 'Use Route Recovery until the lane exits critical status.',
      NARRATIVE_LAB_PATH: '.build/founder/founder-fame-narrative-lab-2026-W24.md',
      RUN_URL: 'https://example.local/run/current',
      CRITICAL_THRESHOLD: '2',
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

  const createdScenario = await runScenario({ issues: [] });
  const createdIssueNumber = Number(createdScenario.outputs.incident_issue_number || '0');
  const createdIssue = getIssueByNumber(createdScenario.issues, createdIssueNumber);
  assertCondition(
    createdScenario.outputs.incident_action === 'created',
    'Expected incident_action=created when critical route state has no prior incident.'
  );
  assertCondition(
    createdScenario.outputs.critical_occurrences === '1',
    'Expected first critical occurrence count to be 1 on create.'
  );
  assertCondition(
    createdScenario.outputs.critical_escalated === 'false',
    'Expected first critical occurrence below threshold to remain monitoring.'
  );
  assertCondition(
    createdIssue && createdIssue.labels.includes('growth-incident') && !createdIssue.labels.includes('growth-critical'),
    'Expected created narrative incident issue to include growth-incident only before threshold is reached.'
  );

  const escalatedScenario = await runScenario({
    issues: [
      createIncidentIssue({
        number: 201,
        criticalOccurrences: 1,
        labels: ['growth-incident']
      })
    ]
  });
  const escalatedIssue = getIssueByNumber(escalatedScenario.issues, 201);
  assertCondition(
    escalatedScenario.outputs.incident_action === 'updated',
    'Expected incident_action=updated when existing incident crosses threshold.'
  );
  assertCondition(
    escalatedScenario.outputs.critical_occurrences === '2' &&
      escalatedScenario.outputs.critical_escalated === 'true',
    'Expected critical escalation on second occurrence at threshold=2.'
  );
  assertCondition(
    escalatedScenario.outputs.critical_assignee_action === 'assigned' &&
      escalatedScenario.outputs.critical_assignee_selected === 'ops-owner',
    'Expected primary narrative route owner to be assigned at escalation.'
  );
  assertCondition(
    escalatedIssue && escalatedIssue.labels.includes('growth-critical'),
    'Expected escalation to apply growth-critical label.'
  );
  assertCondition(
    escalatedScenario.addAssigneeCalls.includes('201:ops-owner'),
    'Expected assignee API call for the primary narrative critical assignee.'
  );

  const fallbackScenario = await runScenario({
    issues: [
      createIncidentIssue({
        number: 202,
        criticalOccurrences: 1,
        labels: ['growth-incident']
      })
    ],
    addAssigneeBehavior: {
      '*:ops-owner': 422
    }
  });
  assertCondition(
    fallbackScenario.outputs.critical_assignee_action === 'assigned' &&
      fallbackScenario.outputs.critical_assignee_selected === 'fallback',
    'Expected fallback assignee selection when primary narrative critical assignee is invalid.'
  );
  assertCondition(
    fallbackScenario.outputs.critical_assignee_attempts.includes('@ops-owner:invalid-or-unassignable') &&
      fallbackScenario.outputs.critical_assignee_attempts.includes('@fallback:assigned'),
    'Expected assignment attempts to record primary failure then fallback success.'
  );

  const assignFailedScenario = await runScenario({
    issues: [
      createIncidentIssue({
        number: 203,
        criticalOccurrences: 1,
        labels: ['growth-incident']
      })
    ],
    addAssigneeBehavior: {
      '*:ops-owner': 422,
      '*:fallback': 404
    }
  });
  assertCondition(
    assignFailedScenario.outputs.critical_assignee_action === 'assign-failed',
    'Expected assign-failed when every narrative critical assignee candidate fails.'
  );
  assertCondition(
    assignFailedScenario.outputs.critical_assignee_selected === '',
    'Expected no selected narrative assignee when assignment fails.'
  );

  const closedScenario = await runScenario({
    issues: [
      createIncidentIssue({
        number: 204,
        criticalOccurrences: 2,
        labels: ['growth-incident', 'growth-critical']
      })
    ],
    envOverrides: {
      ROUTE_MODE: 'Route Compounding',
      ROUTE_LANE_STATUS: 'Stable'
    }
  });
  const closedIssue = getIssueByNumber(closedScenario.issues, 204);
  assertCondition(
    closedScenario.outputs.incident_action === 'closed' &&
      closedScenario.outputs.critical_state === 'false' &&
      closedScenario.outputs.critical_occurrences === '0',
    'Expected stable lane recovery to close incident and reset critical occurrences.'
  );
  assertCondition(
    closedIssue && closedIssue.state === 'closed',
    'Expected narrative route incident issue to close after recovery.'
  );
  assertCondition(
    closedScenario.outputs.critical_assignee_action === 'unassigned' ||
      closedScenario.outputs.critical_assignee_action === 'already-unassigned',
    'Expected assignee cleanup action after recovery closes incident.'
  );

  const duplicateScenario = await runScenario({
    issues: [
      createIncidentIssue({
        number: 210,
        criticalOccurrences: 1,
        labels: ['growth-incident']
      }),
      createIncidentIssue({
        number: 211,
        criticalOccurrences: 1,
        labels: ['growth-incident']
      })
    ]
  });
  const primaryIssue = getIssueByNumber(duplicateScenario.issues, 211);
  const duplicateIssue = getIssueByNumber(duplicateScenario.issues, 210);
  assertCondition(
    duplicateScenario.outputs.incident_issue_number === '211',
    `Expected latest issue #211 to remain primary, got ${duplicateScenario.outputs.incident_issue_number || '(missing)'}.`
  );
  assertCondition(
    primaryIssue && primaryIssue.state === 'open',
    'Expected latest narrative route incident issue to remain open.'
  );
  assertCondition(
    duplicateIssue && duplicateIssue.state === 'closed',
    'Expected duplicate narrative route incident issue to close during reconciliation.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder narrative route incident fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder narrative route incident fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
