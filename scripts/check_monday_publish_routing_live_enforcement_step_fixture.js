#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Enforce Monday publish routing live verification';
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

function runScenario(runScript) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-enforcement-fixture-'));
  const summaryPath = path.join(tmpDir, 'step-summary.md');
  fs.writeFileSync(summaryPath, '', 'utf8');

  const reportPath = '/tmp/monday routing live check/report with spaces.md';

  const commandResult = spawnSync('/bin/zsh', ['-c', runScript], {
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
    stepSummary,
    reportPath
  };
}

function runFixtureSuite() {
  const runScript = extractStepRunScript(workflowPath, stepName);
  const scenario = runScenario(runScript);

  assertCondition(
    scenario.status === 1,
    `Expected enforcement step to exit 1, got ${scenario.status}. stderr=${scenario.stderr}`
  );
  assertCondition(
    scenario.stdout.includes('Monday publish routing live verification failed.'),
    `Expected enforcement step stdout to include failure banner. stdout=${scenario.stdout}`
  );
  assertCondition(
    scenario.stepSummary.includes('- Monday publish routing live verification enforcement: `failed`'),
    `Expected summary enforcement line missing. summary=${scenario.stepSummary}`
  );
  assertCondition(
    scenario.stepSummary.includes(`- Monday publish routing live verification report: \`${scenario.reportPath}\``),
    `Expected summary report path line missing or malformed. summary=${scenario.stepSummary}`
  );
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live enforcement-step fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live enforcement-step fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
