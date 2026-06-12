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

function buildReviewBody({ primaryScript, backupScript, recommendation }) {
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

- Next-week variant recommendation: ${recommendation}
`;
}

function buildMondayDraftBody() {
  return `# Monday Draft

\`\`\`text
MONDAY DRAFT PRIMARY FALLBACK
\`\`\`

\`\`\`text
MONDAY DRAFT BACKUP FALLBACK
\`\`\`
`;
}

function findIssueByTitle(issues, title) {
  return issues.find((issue) => String(issue.title || '') === String(title));
}

function parseDefaultDraftsFromChecklist(body) {
  const text = String(body || '');
  const sourceMatch = text.match(/- Source review artifact:\s*(.*)$/mi);
  const primaryMatch = text.match(/- Primary default draft:\s*(.+?)\s+\(Variant ([A-C]|n\/a)\)\s*\n+\`\`\`text\n([\s\S]*?)\n\`\`\`/im);
  const backupMatch = text.match(/- Backup default draft:\s*(.+?)\s+\(Variant ([A-C]|n\/a)\)\s*\n+\`\`\`text\n([\s\S]*?)\n\`\`\`/im);
  return {
    sourceLabel: sourceMatch ? String(sourceMatch[1] || '').trim() : '',
    primaryChannel: primaryMatch ? String(primaryMatch[1] || '').trim() : '',
    primaryVariant: primaryMatch ? String(primaryMatch[2] || '').trim() : '',
    primaryScript: primaryMatch ? String(primaryMatch[3] || '').trim() : '',
    backupChannel: backupMatch ? String(backupMatch[1] || '').trim() : '',
    backupVariant: backupMatch ? String(backupMatch[2] || '').trim() : '',
    backupScript: backupMatch ? String(backupMatch[3] || '').trim() : ''
  };
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', 'require', script);

  return async function runScenario({ week, reviewBody, envOverrides }) {
    const outputs = {};
    const infoMessages = [];
    const callCounts = {
      getLabel: 0,
      createLabel: 0,
      listForRepo: 0,
      createIssue: 0,
      updateIssue: 0
    };

    const currentIssues = [
      {
        number: 320,
        title: `Weekly Growth Sprint ${week}`,
        body: '- Win Card copies: 12',
        state: 'open',
        labels: ['growth']
      }
    ];
    let nextIssueNumber = 321;
    const labels = new Set(['growth', 'autopilot', 'growth-highlight', 'monday-publish']);

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

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-publish-routing-fixture-'));
    const mondayDraftPath = path.join(tmpDir, 'monday-draft.md');
    const reviewPath = path.join(tmpDir, 'weekly-review.md');
    fs.writeFileSync(mondayDraftPath, buildMondayDraftBody(), 'utf8');
    fs.writeFileSync(reviewPath, String(reviewBody || ''), 'utf8');

    try {
      await executor(github, context, core, {
        env: {
          WEEK: String(week || '2099-W20'),
          SPRINT_ISSUE_NUMBER: '320',
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
      }))
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const backupLeadWithNarrativeSwap = await runScenario({
    week: '2099-W20',
    reviewBody: buildReviewBody({
      primaryScript: 'REVIEW SCRIPT PRIMARY A',
      backupScript: 'REVIEW SCRIPT BACKUP B',
      recommendation: 'Keep proof-first route for next week.'
    }),
    envOverrides: {
      CHANNEL_ROI_PREFERRED_CHANNEL: 'backup',
      NARRATIVE_ROUTE_WINNER: 'proof-first route',
      NARRATIVE_ROUTE_TREND: 'stable',
      NARRATIVE_FAME_VELOCITY_SCORE: '55',
      NARRATIVE_LAUNCH_POSTURE: 'steady',
      NARRATIVE_NEXT_STANDUP_ACTION: 'Capture one winner note.',
      NARRATIVE_ROUTE_RECOMMENDATION: 'Keep route controls locked.'
    }
  });

  assertCondition(
    backupLeadWithNarrativeSwap.callCounts.createIssue === 1 &&
      backupLeadWithNarrativeSwap.callCounts.updateIssue === 0,
    'Expected create path for Monday publish checklist in backup-lead routing scenario.'
  );
  assertCondition(
    backupLeadWithNarrativeSwap.outputs.channel_roi_preferred_channel === 'backup',
    `Expected channel_roi_preferred_channel=backup, got ${backupLeadWithNarrativeSwap.outputs.channel_roi_preferred_channel || '(missing)'}.`
  );
  assertCondition(
    backupLeadWithNarrativeSwap.outputs.narrative_route_preferred_variant === 'A',
    `Expected narrative_route_preferred_variant=A, got ${backupLeadWithNarrativeSwap.outputs.narrative_route_preferred_variant || '(missing)'}.`
  );
  assertCondition(
    backupLeadWithNarrativeSwap.outputs.narrative_route_routing_action === 'promoted-backup-to-primary',
    `Expected narrative_route_routing_action=promoted-backup-to-primary, got ${backupLeadWithNarrativeSwap.outputs.narrative_route_routing_action || '(missing)'}.`
  );
  assertCondition(
    backupLeadWithNarrativeSwap.outputs.default_primary_variant === 'A' &&
      backupLeadWithNarrativeSwap.outputs.default_backup_variant === 'B',
    'Expected final default variants to resolve to primary A and backup B after narrative promotion.'
  );
  assertCondition(
    String(backupLeadWithNarrativeSwap.outputs.default_drafts_source || '').includes('[ROI lead: backup]') &&
      String(backupLeadWithNarrativeSwap.outputs.default_drafts_source || '').includes('[Narrative lead: Variant A]'),
    'Expected default_drafts_source to preserve ROI backup and narrative lead annotations.'
  );

  const backupLeadIssue = findIssueByTitle(
    backupLeadWithNarrativeSwap.issues,
    'Monday Publish Checklist 2099-W20'
  );
  assertCondition(backupLeadIssue, 'Expected backup-lead scenario checklist issue to exist.');
  const backupLeadDrafts = parseDefaultDraftsFromChecklist(backupLeadIssue.body || '');
  assertCondition(
    backupLeadDrafts.primaryChannel === 'X / Threads' &&
      backupLeadDrafts.primaryVariant === 'A' &&
      backupLeadDrafts.primaryScript === 'REVIEW SCRIPT PRIMARY A',
    'Expected backup-lead scenario primary defaults to end on promoted proof-first script A.'
  );
  assertCondition(
    backupLeadDrafts.backupChannel === 'LinkedIn' &&
      backupLeadDrafts.backupVariant === 'B' &&
      backupLeadDrafts.backupScript === 'REVIEW SCRIPT BACKUP B',
    'Expected backup-lead scenario backup defaults to retain backup script B.'
  );

  const forcedNarrativeOverride = await runScenario({
    week: '2099-W21',
    reviewBody: buildReviewBody({
      primaryScript: 'REVIEW SCRIPT PRIMARY FORCED',
      backupScript: 'REVIEW SCRIPT BACKUP FORCED',
      recommendation: 'Keep routing strict and measure outcomes.'
    }),
    envOverrides: {
      CHANNEL_ROI_PREFERRED_CHANNEL: 'balanced',
      NARRATIVE_ROUTE_WINNER: 'objection-handler route',
      NARRATIVE_ROUTE_TREND: 'shifted from proof-first route to objection-breaker route',
      NARRATIVE_FAME_VELOCITY_SCORE: '82',
      NARRATIVE_LAUNCH_POSTURE: 'watch mode',
      NARRATIVE_NEXT_STANDUP_ACTION: 'Log one objection-breaker proof update.',
      NARRATIVE_ROUTE_RECOMMENDATION: 'Lead with objection-breaker evidence this cycle.'
    }
  });

  assertCondition(
    forcedNarrativeOverride.outputs.narrative_route_preferred_variant === 'C',
    `Expected narrative_route_preferred_variant=C, got ${forcedNarrativeOverride.outputs.narrative_route_preferred_variant || '(missing)'}.`
  );
  assertCondition(
    forcedNarrativeOverride.outputs.narrative_route_routing_action === 'forced-primary-variant',
    `Expected narrative_route_routing_action=forced-primary-variant, got ${forcedNarrativeOverride.outputs.narrative_route_routing_action || '(missing)'}.`
  );
  assertCondition(
    forcedNarrativeOverride.outputs.default_primary_variant === 'C' &&
      forcedNarrativeOverride.outputs.default_backup_variant === 'B',
    'Expected forced narrative override to set primary variant C while retaining backup variant B.'
  );
  assertCondition(
    String(forcedNarrativeOverride.outputs.default_drafts_source || '').includes('[Narrative override: Variant C]'),
    'Expected default_drafts_source to include narrative override tag for variant C.'
  );

  const forcedNarrativeIssue = findIssueByTitle(
    forcedNarrativeOverride.issues,
    'Monday Publish Checklist 2099-W21'
  );
  assertCondition(forcedNarrativeIssue, 'Expected forced narrative scenario checklist issue to exist.');
  const forcedDrafts = parseDefaultDraftsFromChecklist(forcedNarrativeIssue.body || '');
  assertCondition(
    forcedDrafts.primaryVariant === 'C' &&
      forcedDrafts.primaryScript === 'REVIEW SCRIPT PRIMARY FORCED',
    'Expected forced narrative scenario primary script to remain promoted script with variant label overridden to C.'
  );

  const watchlistNarrative = await runScenario({
    week: '2099-W22',
    reviewBody: buildReviewBody({
      primaryScript: 'REVIEW SCRIPT PRIMARY WATCHLIST',
      backupScript: 'REVIEW SCRIPT BACKUP WATCHLIST',
      recommendation: 'Observe route signals before changing defaults.'
    }),
    envOverrides: {
      CHANNEL_ROI_PREFERRED_CHANNEL: 'balanced',
      NARRATIVE_ROUTE_WINNER: 'objection-breaker route',
      NARRATIVE_ROUTE_TREND: 'flat',
      NARRATIVE_FAME_VELOCITY_SCORE: '45',
      NARRATIVE_LAUNCH_POSTURE: 'steady',
      NARRATIVE_NEXT_STANDUP_ACTION: 'Collect one more signal.',
      NARRATIVE_ROUTE_RECOMMENDATION: 'Keep watchlist route logged only.'
    }
  });

  assertCondition(
    watchlistNarrative.outputs.narrative_route_preferred_variant === 'C',
    `Expected watchlist narrative preferred variant C, got ${watchlistNarrative.outputs.narrative_route_preferred_variant || '(missing)'}.`
  );
  assertCondition(
    watchlistNarrative.outputs.narrative_route_routing_action === 'watchlist-only',
    `Expected narrative_route_routing_action=watchlist-only, got ${watchlistNarrative.outputs.narrative_route_routing_action || '(missing)'}.`
  );
  assertCondition(
    watchlistNarrative.outputs.default_primary_variant === 'A' &&
      watchlistNarrative.outputs.default_backup_variant === 'B',
    'Expected watchlist narrative scenario to preserve promoted default variants A/B.'
  );
  assertCondition(
    !String(watchlistNarrative.outputs.default_drafts_source || '').includes('[Narrative'),
    'Expected watchlist scenario default_drafts_source to avoid narrative override tags.'
  );

  const watchlistIssue = findIssueByTitle(
    watchlistNarrative.issues,
    'Monday Publish Checklist 2099-W22'
  );
  assertCondition(watchlistIssue, 'Expected watchlist scenario checklist issue to exist.');
  const watchlistDrafts = parseDefaultDraftsFromChecklist(watchlistIssue.body || '');
  assertCondition(
    watchlistDrafts.primaryVariant === 'A' &&
      watchlistDrafts.primaryScript === 'REVIEW SCRIPT PRIMARY WATCHLIST' &&
      watchlistDrafts.backupVariant === 'B' &&
      watchlistDrafts.backupScript === 'REVIEW SCRIPT BACKUP WATCHLIST',
    'Expected watchlist scenario defaults to remain unchanged review-promoted scripts.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Monday publish routing precedence fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Monday publish routing precedence fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
