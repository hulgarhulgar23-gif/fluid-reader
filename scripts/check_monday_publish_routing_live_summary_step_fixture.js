#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Add Monday publish routing verification summary';
const workspaceRoot = path.resolve(__dirname, '..');

function leadingSpaces(value) {
  const match = String(value || '').match(/^(\s*)/);
  return match ? match[1].length : 0;
}

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function extractStepRunScript(filePath, targetStepName) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const stepLineIndex = lines.findIndex((line) => line.includes(`- name: ${targetStepName}`));
  assertCondition(stepLineIndex >= 0, `Could not find workflow step: ${targetStepName}`);

  let runLineIndex = -1;
  for (let index = stepLineIndex + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (index > stepLineIndex + 1 && /^\s*-\s+name:/.test(line)) {
      break;
    }
    if (/^\s*run:\s*\|\s*$/.test(line)) {
      runLineIndex = index;
      break;
    }
  }

  assertCondition(runLineIndex >= 0, `Could not find run block for step: ${targetStepName}`);

  const runIndent = leadingSpaces(lines[runLineIndex]);
  const blockLines = [];
  for (let index = runLineIndex + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === '') {
      blockLines.push('');
      continue;
    }
    const indent = leadingSpaces(line);
    if (indent <= runIndent) {
      break;
    }
    blockLines.push(line);
  }

  const nonEmptyLines = blockLines.filter((line) => line.trim() !== '');
  assertCondition(nonEmptyLines.length > 0, `Workflow run script is empty: ${targetStepName}`);
  const minimumIndent = Math.min(...nonEmptyLines.map((line) => leadingSpaces(line)));
  return blockLines.map((line) => (line.trim() === '' ? '' : line.slice(minimumIndent))).join('\n');
}

function renderGitHubExpressions(runScript, { outcomeValue, exitCodeValue }) {
  return String(runScript || '')
    .replace(
      /\$\{\{\s*steps\.monday_publish_routing_live_verify\.outcome\s*\}\}/g,
      String(outcomeValue)
    )
    .replace(
      /\$\{\{\s*env\.monday_publish_routing_live_check_exit_code\s*\}\}/g,
      String(exitCodeValue)
    );
}

function runScenario(renderedRunScript, { reportPath }) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-summary-fixture-'));
  const summaryPath = path.join(tmpDir, 'step-summary.md');
  fs.writeFileSync(summaryPath, '', 'utf8');

  const commandResult = spawnSync('/bin/zsh', ['-c', renderedRunScript], {
    cwd: workspaceRoot,
    env: {
      ...process.env,
      GITHUB_STEP_SUMMARY: summaryPath,
      monday_publish_routing_live_check_path: reportPath
    },
    encoding: 'utf8'
  });

  const stepSummary = fs.readFileSync(summaryPath, 'utf8');
  fs.rmSync(tmpDir, { recursive: true, force: true });

  return {
    status: Number(commandResult.status),
    stdout: String(commandResult.stdout || ''),
    stderr: String(commandResult.stderr || ''),
    stepSummary
  };
}

function assertSummaryLines(scenario, { reportPath, expectedOutcome, expectedExitCode }) {
  assertCondition(
    scenario.status === 0,
    `Expected summary step to exit 0, got ${scenario.status}. stderr=${scenario.stderr}`
  );
  assertCondition(
    scenario.stepSummary.includes(`- Monday publish routing live verification report: \`${reportPath}\``),
    `Expected summary report path line missing/malformed. summary=${scenario.stepSummary}`
  );
  assertCondition(
    scenario.stepSummary.includes(`- Monday publish routing live verification outcome: \`${expectedOutcome}\``),
    `Expected summary outcome line missing/malformed. summary=${scenario.stepSummary}`
  );
  assertCondition(
    scenario.stepSummary.includes(`- Monday publish routing live verification exit code: \`${expectedExitCode}\``),
    `Expected summary exit-code line missing/malformed. summary=${scenario.stepSummary}`
  );
}

function runFixtureSuite() {
  const rawRunScript = extractStepRunScript(workflowPath, stepName);
  const reportPath = '/tmp/monday routing live check/report with spaces.md';

  const successScript = renderGitHubExpressions(rawRunScript, {
    outcomeValue: 'success',
    exitCodeValue: '0'
  });
  const successScenario = runScenario(successScript, { reportPath });
  assertSummaryLines(successScenario, {
    reportPath,
    expectedOutcome: 'success',
    expectedExitCode: '0'
  });

  const failureScript = renderGitHubExpressions(rawRunScript, {
    outcomeValue: 'failure',
    exitCodeValue: '7'
  });
  const failureScenario = runScenario(failureScript, { reportPath });
  assertSummaryLines(failureScenario, {
    reportPath,
    expectedOutcome: 'failure',
    expectedExitCode: '7'
  });
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live summary-step fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live summary-step fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
