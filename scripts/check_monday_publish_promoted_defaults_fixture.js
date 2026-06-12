#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Upsert Monday publish checklist issue';

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

function buildReviewWithPromotedScripts({ primaryScript, backupScript }) {
  return `<!-- weekly-growth-review -->

### Next-Week Channel Scripts

- Primary channel (\`X / Threads\`): Variant A

\`\`\`text
${primaryScript}
\`\`\`

- Backup channel (\`LinkedIn\`): Variant B

\`\`\`text
${backupScript}
\`\`\`

- Next-week variant recommendation: Keep winner alignment tight.
`;
}

function buildReviewWithoutScriptSection() {
  return `<!-- weekly-growth-review -->

### Sprint Snapshot

- Win Card copies: 12
- Next-week variant recommendation: Keep winner alignment tight.
`;
}

function buildMondayDraftWithHeadingPromotedDefaults({
  sourceLabel,
  primaryChannel,
  primaryVariant,
  primaryScript,
  backupChannel,
  backupVariant,
  backupScript
}) {
  return `# Monday Draft

## Default Publish Drafts (Auto-Promoted)

- Source review artifact: ${sourceLabel}
- Primary default draft: ${primaryChannel} (Variant ${primaryVariant})

\`\`\`text
${primaryScript}
\`\`\`

- Backup default draft: ${backupChannel} (Variant ${backupVariant})

\`\`\`text
${backupScript}
\`\`\`

## Monday Draft Source

Fallback draft source block.
`;
}

function findIssueByTitle(issues, title) {
  return issues.find((issue) => String(issue.title || '') === String(title));
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', 'require', script);

  return async function runScenario({
    week,
    reviewBody,
    mondayDraftBody,
    initialIssues,
    existingLabels,
    envOverrides
  }) {
    const outputs = {};
    const infoMessages = [];
    const callCounts = {
      getLabel: 0,
      createLabel: 0,
      listForRepo: 0,
      createIssue: 0,
      updateIssue: 0
    };

    const currentIssues = Array.isArray(initialIssues)
      ? initialIssues.map((issue) => ({
          number: Number(issue.number),
          title: String(issue.title || ''),
          body: String(issue.body || ''),
          state: String(issue.state || 'open'),
          labels: Array.isArray(issue.labels) ? [...issue.labels] : [],
          pull_request: issue.pull_request
        }))
      : [];
    let nextIssueNumber = currentIssues.reduce((max, issue) => Math.max(max, Number(issue.number) || 0), 0) + 1;
    const labels = new Set(Array.isArray(existingLabels) ? existingLabels.map((label) => String(label)) : []);

    const github = {
      rest: {
        issues: {
          getLabel: async ({ name }) => {
            callCounts.getLabel += 1;
            if (!labels.has(String(name))) {
              throw { status: 404 };
            }
            return { data: { name: String(name) } };
          },
          createLabel: async ({ name }) => {
            callCounts.createLabel += 1;
            labels.add(String(name));
            return { data: { name: String(name) } };
          },
          listForRepo: async () => {
            callCounts.listForRepo += 1;
            return {
              data: currentIssues.map((issue) => ({
                ...issue,
                labels: Array.isArray(issue.labels) ? [...issue.labels] : []
              }))
            };
          },
          create: async ({ title, body, labels: appliedLabels }) => {
            callCounts.createIssue += 1;
            const created = {
              number: nextIssueNumber,
              title: String(title || ''),
              body: String(body || ''),
              state: 'open',
              labels: Array.isArray(appliedLabels) ? [...appliedLabels] : []
            };
            nextIssueNumber += 1;
            currentIssues.push(created);
            return {
              data: {
                ...created,
                labels: [...created.labels]
              }
            };
          },
          update: async ({ issue_number, state, body, labels: appliedLabels }) => {
            callCounts.updateIssue += 1;
            const targetIndex = currentIssues.findIndex(
              (issue) => String(issue.number) === String(issue_number)
            );
            assertCondition(targetIndex >= 0, `Cannot update missing issue #${issue_number}.`);
            currentIssues[targetIndex] = {
              ...currentIssues[targetIndex],
              state: String(state || currentIssues[targetIndex].state || 'open'),
              body: String(body || ''),
              labels: Array.isArray(appliedLabels) ? [...appliedLabels] : currentIssues[targetIndex].labels
            };
            return {
              data: {
                ...currentIssues[targetIndex],
                labels: [...(currentIssues[targetIndex].labels || [])]
              }
            };
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

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-publish-fixture-'));
    const mondayDraftPath = path.join(tmpDir, 'monday-draft.md');
    const reviewPath = path.join(tmpDir, 'weekly-review.md');
    fs.writeFileSync(mondayDraftPath, String(mondayDraftBody || ''), 'utf8');
    fs.writeFileSync(reviewPath, String(reviewBody || ''), 'utf8');

    try {
      await executor(github, context, core, {
        env: {
          WEEK: String(week || '2099-W02'),
          SPRINT_ISSUE_NUMBER: '71',
          HIGHLIGHT_PLAN_ISSUE_NUMBER: '17',
          MONDAY_DRAFT_PATH: mondayDraftPath,
          REVIEW_PATH: reviewPath,
          PRIMARY_CHANNEL: 'X / Threads',
          BACKUP_CHANNEL: 'LinkedIn',
          STRONGEST_METRIC_LABEL: 'Win Card copies',
          STRONGEST_METRIC_VALUE: '12',
          ...(envOverrides || {})
        }
      }, require);
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }

    return {
      outputs,
      infoMessages,
      callCounts,
      reviewPath,
      issues: currentIssues.map((issue) => ({
        ...issue,
        labels: Array.isArray(issue.labels) ? [...issue.labels] : []
      })),
      labels: [...labels]
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const createWeek = '2099-W02';
  const createChecklistTitle = `Monday Publish Checklist ${createWeek}`;
  const createdScenario = await runScenario({
    week: createWeek,
    reviewBody: buildReviewWithPromotedScripts({
      primaryScript: 'REVIEW PRIMARY DEFAULT SCRIPT',
      backupScript: 'REVIEW BACKUP DEFAULT SCRIPT'
    }),
    mondayDraftBody: buildMondayDraftWithHeadingPromotedDefaults({
      sourceLabel: 'monday-draft-heading-fallback-source',
      primaryChannel: 'X / Threads',
      primaryVariant: 'C',
      primaryScript: 'MONDAY DRAFT PRIMARY FALLBACK SCRIPT',
      backupChannel: 'LinkedIn',
      backupVariant: 'A',
      backupScript: 'MONDAY DRAFT BACKUP FALLBACK SCRIPT'
    }),
    initialIssues: [
      {
        number: 400,
        title: 'Weekly Growth Sprint 2099-W02',
        body: '- Win Card copies: 12'
      }
    ],
    existingLabels: ['growth', 'autopilot', 'growth-highlight']
  });

  assertCondition(
    createdScenario.callCounts.createIssue === 1 && createdScenario.callCounts.updateIssue === 0,
    'Expected Monday publish checklist create path when issue does not exist.'
  );
  assertCondition(
    createdScenario.callCounts.createLabel === 1,
    'Expected monday-publish label to be created when missing.'
  );
  assertCondition(
    createdScenario.outputs.default_primary_variant === 'A' &&
      createdScenario.outputs.default_backup_variant === 'B',
    'Expected Monday publish defaults to use promoted review variants A/B.'
  );
  assertCondition(
    createdScenario.outputs.default_drafts_source === createdScenario.reviewPath,
    'Expected Monday publish default source to resolve to review artifact path when scripts are parseable.'
  );

  const createdChecklistIssue = findIssueByTitle(createdScenario.issues, createChecklistTitle);
  assertCondition(createdChecklistIssue, 'Expected created Monday publish checklist issue to exist.');
  assertCondition(
    String(createdChecklistIssue.body || '').includes(`- Source review artifact: ${createdScenario.reviewPath}`),
    'Expected created checklist body to reference review artifact source label.'
  );
  assertCondition(
    String(createdChecklistIssue.body || '').includes('REVIEW PRIMARY DEFAULT SCRIPT') &&
      String(createdChecklistIssue.body || '').includes('REVIEW BACKUP DEFAULT SCRIPT'),
    'Expected created checklist body to include promoted review scripts.'
  );

  const updateWeek = '2099-W03';
  const updateChecklistTitle = `Monday Publish Checklist ${updateWeek}`;
  const updatedScenario = await runScenario({
    week: updateWeek,
    reviewBody: buildReviewWithoutScriptSection(),
    mondayDraftBody: buildMondayDraftWithHeadingPromotedDefaults({
      sourceLabel: 'monday-draft-heading-source',
      primaryChannel: 'X / Threads',
      primaryVariant: 'C',
      primaryScript: 'HEADING FALLBACK PRIMARY SCRIPT',
      backupChannel: 'LinkedIn',
      backupVariant: 'A',
      backupScript: 'HEADING FALLBACK BACKUP SCRIPT'
    }),
    initialIssues: [
      {
        number: 510,
        title: updateChecklistTitle,
        body: '# Monday Publish Checklist (legacy)\n- Monday post status: not posted'
      }
    ],
    existingLabels: ['growth', 'autopilot', 'growth-highlight', 'monday-publish']
  });

  assertCondition(
    updatedScenario.callCounts.createIssue === 0 && updatedScenario.callCounts.updateIssue === 1,
    'Expected Monday publish checklist update path when issue already exists.'
  );
  assertCondition(
    updatedScenario.callCounts.createLabel === 0,
    'Expected no label creation when monday-publish label already exists.'
  );
  assertCondition(
    updatedScenario.outputs.default_drafts_source === 'monday-draft-heading-source',
    'Expected Monday publish defaults to fall back to Monday draft heading source.'
  );
  assertCondition(
    updatedScenario.outputs.default_primary_variant === 'C' &&
      updatedScenario.outputs.default_backup_variant === 'A',
    'Expected Monday publish fallback defaults to preserve heading variants C/A.'
  );

  const updatedChecklistIssue = findIssueByTitle(updatedScenario.issues, updateChecklistTitle);
  assertCondition(updatedChecklistIssue, 'Expected updated Monday publish checklist issue to exist.');
  assertCondition(
    String(updatedChecklistIssue.body || '').includes('- Source review artifact: monday-draft-heading-source'),
    'Expected updated checklist body to include Monday draft heading source line.'
  );
  assertCondition(
    String(updatedChecklistIssue.body || '').includes('HEADING FALLBACK PRIMARY SCRIPT') &&
      String(updatedChecklistIssue.body || '').includes('HEADING FALLBACK BACKUP SCRIPT'),
    'Expected updated checklist body to include heading-derived fallback scripts.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Monday publish promoted-defaults fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Monday publish promoted-defaults fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
