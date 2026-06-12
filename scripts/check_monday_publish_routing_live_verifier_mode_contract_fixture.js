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

function runScenario(args, envOverrides = {}) {
  const commandResult = spawnSync('/bin/zsh', [verifierScriptPath, ...args], {
    cwd: workspaceRoot,
    env: {
      ...process.env,
      ...envOverrides
    },
    encoding: 'utf8'
  });

  return {
    status: Number(commandResult.status),
    stdout: String(commandResult.stdout || ''),
    stderr: String(commandResult.stderr || '')
  };
}

function runFixtureSuite() {
  const strictWithoutIssue = runScenario([
    '--repo',
    'owner/repo',
    '--strict'
  ]);

  assertCondition(
    strictWithoutIssue.status === 1,
    `Expected strict mode without --issue to fail with exit 1, got ${strictWithoutIssue.status}. stderr=${strictWithoutIssue.stderr}`
  );
  assertCondition(
    strictWithoutIssue.stderr.includes('--strict live mode requires --issue <number>.'),
    `Expected strict-mode guidance error message missing. stderr=${strictWithoutIssue.stderr}`
  );

  const sampleWithReview = runScenario([
    '--sample',
    '--review',
    'sample-weekly-review.md'
  ]);

  assertCondition(
    sampleWithReview.status === 1,
    `Expected --sample with --review to fail with exit 1, got ${sampleWithReview.status}. stderr=${sampleWithReview.stderr}`
  );
  assertCondition(
    sampleWithReview.stderr.includes('--sample cannot be combined with --checklist, --review, or --issue.'),
    `Expected sample/review exclusivity error message missing. stderr=${sampleWithReview.stderr}`
  );

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-mode-fixture-'));
  const outPath = path.join(tmpDir, 'monday-routing-live-report.md');
  const strictOutPath = path.join(tmpDir, 'monday-routing-live-strict-report.md');
  const ghStubPath = path.join(tmpDir, 'gh');
  try {
    const nonStrictWithoutIssue = runScenario([
      '--repo',
      'owner/repo',
      '--out',
      outPath
    ]);

    assertCondition(
      nonStrictWithoutIssue.status === 0,
      `Expected non-strict live mode without --issue to pass, got ${nonStrictWithoutIssue.status}. stderr=${nonStrictWithoutIssue.stderr}`
    );
    assertCondition(
      fs.existsSync(outPath),
      `Expected verifier report output for non-strict mode scenario: ${outPath}`
    );
    const outputBody = fs.readFileSync(outPath, 'utf8');
    assertCondition(
      outputBody.includes('- Mode: live'),
      `Expected live mode metadata in non-strict output report. output=${outputBody}`
    );
    assertCondition(
      outputBody.includes('- Result: PASS'),
      `Expected PASS verdict in non-strict output report. output=${outputBody}`
    );
    assertCondition(
      outputBody.includes('Checklist marker: skipped: checklist body unavailable'),
      `Expected checklist skip guidance in non-strict output report. output=${outputBody}`
    );
    assertCondition(
      outputBody.includes('Routing field parsing: skipped: checklist body unavailable') &&
        outputBody.includes('Routing consistency checks: skipped: checklist body unavailable'),
      `Expected routing-skip guidance in non-strict output report. output=${outputBody}`
    );

    fs.writeFileSync(
      ghStubPath,
      '#!/usr/bin/env bash\nset -euo pipefail\nexit 1\n',
      'utf8'
    );
    fs.chmodSync(ghStubPath, 0o755);

    const strictWithIssueGhFailure = runScenario(
      [
        '--repo',
        'owner/repo',
        '--issue',
        '123',
        '--strict',
        '--out',
        strictOutPath
      ],
      {
        PATH: `${tmpDir}:${process.env.PATH || ''}`
      }
    );

    assertCondition(
      strictWithIssueGhFailure.status === 1,
      `Expected strict live mode with unresolved checklist fetch to fail with exit 1, got ${strictWithIssueGhFailure.status}. stderr=${strictWithIssueGhFailure.stderr}`
    );
    assertCondition(
      fs.existsSync(strictOutPath),
      `Expected strict-mode failure report output when checklist fetch fails: ${strictOutPath}`
    );
    const strictOutputBody = fs.readFileSync(strictOutPath, 'utf8');
    assertCondition(
      strictOutputBody.includes('- Result: FAIL'),
      `Expected FAIL verdict in strict-mode report when checklist fetch fails. output=${strictOutputBody}`
    );
    assertCondition(
      strictOutputBody.includes('Checklist marker: skipped: checklist body unavailable') &&
        strictOutputBody.includes('Checklist default drafts section: skipped: checklist body unavailable'),
      `Expected checklist missing-data lines in strict-mode report. output=${strictOutputBody}`
    );
    assertCondition(
      strictOutputBody.includes('Routing field parsing: skipped: checklist body unavailable') &&
        strictOutputBody.includes('Routing consistency checks: skipped: checklist body unavailable'),
      `Expected routing missing-data lines in strict-mode report. output=${strictOutputBody}`
    );
  } finally {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live verifier mode-contract fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live verifier mode-contract fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
