#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Extract previous Monday checklist effectiveness';
const guestingMarker = '<!-- weekly-growth-founder-guesting-signal -->';

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

function buildGuestingComment(entries) {
  const lines = [guestingMarker, '', '## Founder Guesting Signal Intake'];
  for (const entry of entries) {
    lines.push(`- Target: ${entry.target}`);
    lines.push(`- Format: ${entry.format}`);
    lines.push(`- Stage: ${entry.stage}`);
    lines.push(`- Lead channel: ${entry.channel}`);
    lines.push(`- Priority score: ${entry.priority}`);
    lines.push(`- Warm intro: ${entry.warmIntro}`);
    lines.push(`- Status: ${entry.status}`);
    lines.push('');
  }
  return lines.join('\n');
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
          body: buildGuestingComment([
            {
              target: 'Growth Weekly Podcast',
              format: 'podcast',
              stage: 'booked',
              channel: 'primary',
              priority: '88',
              warmIntro: 'yes',
              status: 'booked intro'
            },
            {
              target: 'SaaS Builder News',
              format: 'newsletter',
              stage: 'replied',
              channel: 'backup',
              priority: '72',
              warmIntro: 'no',
              status: 'replied'
            },
            {
              target: 'Operator Insights Live',
              format: 'podcast',
              stage: 'published',
              channel: 'primary',
              priority: '91',
              warmIntro: 'yes',
              status: 'published'
            }
          ])
        }
      ],
      222: [
        {
          body: buildGuestingComment([
            {
              target: 'Launch Notes Podcast',
              format: 'podcast',
              stage: 'replied',
              channel: 'primary',
              priority: '70',
              warmIntro: 'no',
              status: 'replied'
            },
            {
              target: 'Builder Weekly',
              format: 'newsletter',
              stage: 'pitched',
              channel: 'backup',
              priority: '65',
              warmIntro: 'no',
              status: 'pitched'
            }
          ])
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

  assertCondition(scenario.outputs.guesting_signal_entries === '3', 'Expected guesting_signal_entries=3.');
  assertCondition(scenario.outputs.guesting_signal_entries_delta === '+1', 'Expected guesting_signal_entries_delta=+1.');
  assertCondition(scenario.outputs.guesting_signal_replied === '2', 'Expected guesting_signal_replied=2.');
  assertCondition(scenario.outputs.guesting_signal_replied_delta === '+2', 'Expected guesting_signal_replied_delta=+2.');
  assertCondition(scenario.outputs.guesting_signal_booked === '2', 'Expected guesting_signal_booked=2.');
  assertCondition(scenario.outputs.guesting_signal_booked_delta === '+2', 'Expected guesting_signal_booked_delta=+2.');
  assertCondition(scenario.outputs.guesting_signal_published === '1', 'Expected guesting_signal_published=1.');
  assertCondition(scenario.outputs.guesting_signal_published_delta === '+1', 'Expected guesting_signal_published_delta=+1.');
  assertCondition(scenario.outputs.guesting_signal_primary_signals === '2', 'Expected guesting_signal_primary_signals=2.');
  assertCondition(scenario.outputs.guesting_signal_primary_signals_delta === '+1', 'Expected guesting_signal_primary_signals_delta=+1.');
  assertCondition(scenario.outputs.guesting_signal_backup_signals === '1', 'Expected guesting_signal_backup_signals=1.');
  assertCondition(scenario.outputs.guesting_signal_backup_signals_delta === '0', 'Expected guesting_signal_backup_signals_delta=0.');
  assertCondition(scenario.outputs.guesting_signal_top_format === 'podcast', 'Expected guesting_signal_top_format=podcast.');
  assertCondition(
    scenario.outputs.guesting_signal_top_target === 'Operator Insights Live',
    `Expected guesting_signal_top_target=Operator Insights Live, got ${scenario.outputs.guesting_signal_top_target || '(missing)'}`
  );
  assertCondition(scenario.outputs.guesting_signal_enrichment_score === '88%', 'Expected guesting_signal_enrichment_score=88%.');
  assertCondition(
    scenario.outputs.guesting_signal_enrichment_score_delta === '+54pp',
    `Expected guesting_signal_enrichment_score_delta=+54pp, got ${scenario.outputs.guesting_signal_enrichment_score_delta || '(missing)'}`
  );
  assertCondition(
    String(scenario.outputs.guesting_signal_recommendation || '').includes('Prioritize booked/published guesting targets first'),
    'Expected high-confidence guesting recommendation from parsed entries.'
  );

  const noSignalScenario = await runScenario({
    issues: [previousWeekChecklist],
    commentsByIssue: {
      231: [{ body: 'No marker comment yet.' }]
    },
    envOverrides: {
      PREVIOUS_WEEK: '2026-W23',
      PREVIOUS_BASELINE_WEEK: ''
    }
  });

  assertCondition(
    noSignalScenario.outputs.guesting_signal_entries === 'n/a',
    `Expected guesting_signal_entries=n/a when marker is absent, got ${noSignalScenario.outputs.guesting_signal_entries || '(missing)'}`
  );
  assertCondition(
    String(noSignalScenario.outputs.guesting_signal_recommendation || '').includes('Capture founder guesting signal comments'),
    'Expected default guesting recommendation when marker is absent.'
  );
}

runFixtureSuite()
  .then(() => {
    console.log('Founder guesting signal fixture checks passed.');
  })
  .catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
