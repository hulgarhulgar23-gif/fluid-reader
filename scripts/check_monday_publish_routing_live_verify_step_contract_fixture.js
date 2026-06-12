#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Verify Monday publish routing live state';

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function extractStepBlock(filePath, targetStepName) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const stepLineIndex = lines.findIndex((line) => line.includes(`- name: ${targetStepName}`));
  assertCondition(stepLineIndex >= 0, `Could not find workflow step: ${targetStepName}`);

  const blockLines = [];
  for (let index = stepLineIndex; index < lines.length; index += 1) {
    const line = lines[index];
    if (index > stepLineIndex && /^\s*-\s+name:/.test(line)) {
      break;
    }
    blockLines.push(line);
  }
  return blockLines.join('\n');
}

function runFixtureSuite() {
  const stepBlock = extractStepBlock(workflowPath, stepName);

  assertCondition(
    stepBlock.includes('id: monday_publish_routing_live_verify'),
    'Expected Monday routing live-verify step id wiring.'
  );
  assertCondition(
    stepBlock.includes("if: steps.monday_publish.outputs.monday_publish_issue_number != '' && env.review_path != ''"),
    'Expected Monday routing live-verify step if-guard wiring.'
  );
  assertCondition(
    stepBlock.includes('continue-on-error: true'),
    'Expected Monday routing live-verify step continue-on-error wiring.'
  );
  assertCondition(
    stepBlock.includes('REPO_SLUG: ${{ github.repository }}'),
    'Expected REPO_SLUG env wiring for Monday routing live-verify step.'
  );
  assertCondition(
    stepBlock.includes('CHECKLIST_ISSUE_NUMBER: ${{ steps.monday_publish.outputs.monday_publish_issue_number }}'),
    'Expected CHECKLIST_ISSUE_NUMBER env wiring for Monday routing live-verify step.'
  );
  assertCondition(
    stepBlock.includes('REVIEW_PATH: ${{ env.review_path }}'),
    'Expected REVIEW_PATH env wiring for Monday routing live-verify step.'
  );

  assertCondition(
    stepBlock.includes('zsh scripts/verify_monday_publish_routing_run.sh \\'),
    'Expected Monday routing live-verify script invocation.'
  );
  assertCondition(
    stepBlock.includes('--repo "$REPO_SLUG" \\'),
    'Expected --repo wiring in Monday routing live-verify invocation.'
  );
  assertCondition(
    stepBlock.includes('--issue "$CHECKLIST_ISSUE_NUMBER" \\'),
    'Expected --issue wiring in Monday routing live-verify invocation.'
  );
  assertCondition(
    stepBlock.includes('--review "$REVIEW_PATH" \\'),
    'Expected --review wiring in Monday routing live-verify invocation.'
  );
  assertCondition(
    stepBlock.includes('--strict \\'),
    'Expected --strict flag in Monday routing live-verify invocation.'
  );
  assertCondition(
    stepBlock.includes('--out "$report_path"'),
    'Expected --out wiring in Monday routing live-verify invocation.'
  );

  assertCondition(
    stepBlock.includes('echo "monday_publish_routing_live_check_path=$report_path" >> "$GITHUB_ENV"'),
    'Expected live-check-path output wiring for Monday routing live-verify step.'
  );
  assertCondition(
    stepBlock.includes('echo "monday_publish_routing_live_check_exit_code=$verify_exit_code" >> "$GITHUB_ENV"'),
    'Expected exit-code output wiring for Monday routing live-verify step.'
  );
  assertCondition(
    stepBlock.includes('exit "$verify_exit_code"'),
    'Expected explicit exit-code propagation in Monday routing live-verify step.'
  );
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live-verify step contract fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live-verify step contract fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
