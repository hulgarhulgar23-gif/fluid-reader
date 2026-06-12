#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const workspaceRoot = path.resolve(__dirname, '..');
const verifierScriptPath = path.resolve(__dirname, './verify_monday_publish_routing_run.sh');

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function runScenario(args) {
  const commandResult = spawnSync('/bin/zsh', [verifierScriptPath, ...args], {
    cwd: workspaceRoot,
    env: {
      ...process.env
    },
    encoding: 'utf8'
  });

  return {
    status: Number(commandResult.status),
    stdout: String(commandResult.stdout || ''),
    stderr: String(commandResult.stderr || '')
  };
}

function buildChecklistBody() {
  return `<!-- weekly-growth-monday-publish-checklist -->
# Monday Publish Checklist: 2099-W44

## First 24-Hour Reply Effectiveness

- Channel ROI preferred channel: backup
- Founder narrative preferred variant: A
- Founder narrative routing action: promoted-backup-to-primary

## Default Publish Drafts (Auto-Promoted)

- Source review artifact: .build/growth/2099-W44-review.md [ROI lead: backup] [Narrative lead: Variant A]
- Primary default draft: X / Threads (Variant A)

\`\`\`text
REVIEW PRIMARY SCRIPT A
\`\`\`

- Backup default draft: LinkedIn (Variant B)

\`\`\`text
REVIEW BACKUP SCRIPT B
\`\`\`
`;
}

function runFixtureSuite() {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-review-availability-fixture-'));
  const checklistPath = path.join(tmpDir, 'monday-checklist.md');
  const strictNoReviewOutPath = path.join(tmpDir, 'monday-routing-live-strict-no-review-report.md');
  const nonStrictOutPath = path.join(tmpDir, 'monday-routing-live-nonstrict-report.md');
  const strictOutPath = path.join(tmpDir, 'monday-routing-live-strict-report.md');
  const missingReviewPath = path.join(tmpDir, 'missing review artifact.md');

  fs.writeFileSync(checklistPath, buildChecklistBody(), 'utf8');

  try {
    const strictNoReviewScenario = runScenario([
      '--checklist',
      checklistPath,
      '--strict',
      '--out',
      strictNoReviewOutPath
    ]);

    assertCondition(
      strictNoReviewScenario.status === 0,
      `Expected strict verifier without --review path to pass, got ${strictNoReviewScenario.status}. stderr=${strictNoReviewScenario.stderr}`
    );
    assertCondition(
      fs.existsSync(strictNoReviewOutPath),
      `Expected strict no-review output report: ${strictNoReviewOutPath}`
    );
    const strictNoReviewOutputBody = fs.readFileSync(strictNoReviewOutPath, 'utf8');
    assertCondition(
      strictNoReviewOutputBody.includes('- Mode: checklist'),
      `Expected checklist mode metadata in strict no-review output report. output=${strictNoReviewOutputBody}`
    );
    assertCondition(
      strictNoReviewOutputBody.includes('- Result: PASS'),
      `Expected PASS verdict in strict no-review output report. output=${strictNoReviewOutputBody}`
    );
    assertCondition(
      strictNoReviewOutputBody.includes('Review artifact availability: skipped: no --review path provided'),
      `Expected strict no-review availability skip line in output report. output=${strictNoReviewOutputBody}`
    );

    const nonStrictScenario = runScenario([
      '--checklist',
      checklistPath,
      '--review',
      missingReviewPath,
      '--out',
      nonStrictOutPath
    ]);

    assertCondition(
      nonStrictScenario.status === 0,
      `Expected non-strict verifier with missing review file to pass, got ${nonStrictScenario.status}. stderr=${nonStrictScenario.stderr}`
    );
    assertCondition(
      fs.existsSync(nonStrictOutPath),
      `Expected non-strict output report: ${nonStrictOutPath}`
    );
    const nonStrictOutputBody = fs.readFileSync(nonStrictOutPath, 'utf8');
    assertCondition(
      nonStrictOutputBody.includes('- Mode: checklist'),
      `Expected checklist mode metadata in non-strict output report. output=${nonStrictOutputBody}`
    );
    assertCondition(
      nonStrictOutputBody.includes('- Result: PASS'),
      `Expected PASS verdict in non-strict output report. output=${nonStrictOutputBody}`
    );
    assertCondition(
      nonStrictOutputBody.includes(`Review artifact availability: skipped: review file not found (${missingReviewPath})`),
      `Expected non-strict review-availability skip line in output report. output=${nonStrictOutputBody}`
    );

    const strictScenario = runScenario([
      '--checklist',
      checklistPath,
      '--review',
      missingReviewPath,
      '--strict',
      '--out',
      strictOutPath
    ]);

    assertCondition(
      strictScenario.status === 1,
      `Expected strict verifier with missing review file to fail, got ${strictScenario.status}. stderr=${strictScenario.stderr}`
    );
    assertCondition(
      fs.existsSync(strictOutPath),
      `Expected strict output report: ${strictOutPath}`
    );
    const strictOutputBody = fs.readFileSync(strictOutPath, 'utf8');
    assertCondition(
      strictOutputBody.includes('- Mode: checklist'),
      `Expected checklist mode metadata in strict output report. output=${strictOutputBody}`
    );
    assertCondition(
      strictOutputBody.includes('- Result: FAIL'),
      `Expected FAIL verdict in strict output report. output=${strictOutputBody}`
    );
    assertCondition(
      strictOutputBody.includes(`Review artifact availability: review file not found (${missingReviewPath})`),
      `Expected strict review-availability failure line in output report. output=${strictOutputBody}`
    );
  } finally {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live verifier review-availability contract fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live verifier review-availability contract fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
