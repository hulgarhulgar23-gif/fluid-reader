#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Verify Monday publish routing live state';
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

function parseGitHubEnv(content) {
  const values = {};
  const lines = String(content || '').split(/\r?\n/);
  for (const line of lines) {
    if (!line || !line.includes('=')) continue;
    const splitIndex = line.indexOf('=');
    const key = line.slice(0, splitIndex).trim();
    const value = line.slice(splitIndex + 1).trim();
    if (!key) continue;
    values[key] = value;
  }
  return values;
}

function getFlagValue(args, flag) {
  const index = args.findIndex((item) => item === flag);
  if (index < 0) return '';
  if (index + 1 >= args.length) return '';
  return String(args[index + 1] || '');
}

function runScenario(runScript, expectedExitCode) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-live-step-fixture-'));
  const stubZshPath = path.join(tmpDir, 'zsh');
  const stubArgsPath = path.join(tmpDir, 'stub-args.txt');
  const githubEnvPath = path.join(tmpDir, 'github-env.txt');

const stubScript = `#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "$@" > "$STUB_ARGS_FILE"
exit "\${STUB_EXIT_CODE:-0}"
`;
  fs.writeFileSync(stubZshPath, stubScript, 'utf8');
  fs.chmodSync(stubZshPath, 0o755);
  fs.writeFileSync(githubEnvPath, '', 'utf8');

  const commandResult = spawnSync('/bin/zsh', ['-c', runScript], {
    cwd: workspaceRoot,
    env: {
      ...process.env,
      PATH: `${tmpDir}:${process.env.PATH || ''}`,
      STUB_ARGS_FILE: stubArgsPath,
      STUB_EXIT_CODE: String(expectedExitCode),
      GITHUB_ENV: githubEnvPath,
      WEEK: '2099-W44',
      REPO_SLUG: 'owner/repo',
      CHECKLIST_ISSUE_NUMBER: '123',
      REVIEW_PATH: '/tmp/review artifact.md'
    },
    encoding: 'utf8'
  });

  const parsedEnv = parseGitHubEnv(fs.readFileSync(githubEnvPath, 'utf8'));
  const stubArgs = fs.existsSync(stubArgsPath)
    ? fs.readFileSync(stubArgsPath, 'utf8').split(/\r?\n/).filter((line) => line.length > 0)
    : [];

  fs.rmSync(tmpDir, { recursive: true, force: true });

  return {
    status: Number(commandResult.status),
    stdout: String(commandResult.stdout || ''),
    stderr: String(commandResult.stderr || ''),
    parsedEnv,
    stubArgs
  };
}

function assertExpectedInvocation(args) {
  assertCondition(args.length > 0, 'Expected Monday routing verifier command invocation arguments.');
  assertCondition(
    args[0] === 'scripts/verify_monday_publish_routing_run.sh',
    `Expected verifier script path as first argument, got: ${args[0] || '(missing)'}`
  );

  const repoValue = getFlagValue(args, '--repo');
  const issueValue = getFlagValue(args, '--issue');
  const reviewValue = getFlagValue(args, '--review');
  const outValue = getFlagValue(args, '--out');

  assertCondition(repoValue === 'owner/repo', `Expected --repo owner/repo, got ${repoValue || '(missing)'}`);
  assertCondition(issueValue === '123', `Expected --issue 123, got ${issueValue || '(missing)'}`);
  assertCondition(
    reviewValue === '/tmp/review artifact.md',
    `Expected --review path to preserve spaces, got ${reviewValue || '(missing)'}`
  );
  assertCondition(
    outValue === '.build/growth/2099-W44-monday-publish-routing-live-check.md',
    `Expected --out path wiring, got ${outValue || '(missing)'}`
  );
  assertCondition(args.includes('--strict'), 'Expected --strict flag to be passed to live verifier.');
}

async function runFixtureSuite() {
  const runScript = extractStepRunScript(workflowPath, stepName);

  const successScenario = runScenario(runScript, 0);
  assertCondition(
    successScenario.status === 0,
    `Expected successful verifier step scenario to exit 0, got ${successScenario.status}. stderr=${successScenario.stderr}`
  );
  assertExpectedInvocation(successScenario.stubArgs);
  assertCondition(
    successScenario.parsedEnv.monday_publish_routing_live_check_path ===
      '.build/growth/2099-W44-monday-publish-routing-live-check.md',
    `Expected monday_publish_routing_live_check_path output wiring, got ${
      successScenario.parsedEnv.monday_publish_routing_live_check_path || '(missing)'
    }`
  );
  assertCondition(
    successScenario.parsedEnv.monday_publish_routing_live_check_exit_code === '0',
    `Expected monday_publish_routing_live_check_exit_code=0, got ${
      successScenario.parsedEnv.monday_publish_routing_live_check_exit_code || '(missing)'
    }`
  );

  const failingScenario = runScenario(runScript, 7);
  assertCondition(
    failingScenario.status === 7,
    `Expected failing verifier step scenario to propagate exit 7, got ${failingScenario.status}. stderr=${failingScenario.stderr}`
  );
  assertExpectedInvocation(failingScenario.stubArgs);
  assertCondition(
    failingScenario.parsedEnv.monday_publish_routing_live_check_path ===
      '.build/growth/2099-W44-monday-publish-routing-live-check.md',
    `Expected monday_publish_routing_live_check_path output on failure scenario, got ${
      failingScenario.parsedEnv.monday_publish_routing_live_check_path || '(missing)'
    }`
  );
  assertCondition(
    failingScenario.parsedEnv.monday_publish_routing_live_check_exit_code === '7',
    `Expected monday_publish_routing_live_check_exit_code=7, got ${
      failingScenario.parsedEnv.monday_publish_routing_live_check_exit_code || '(missing)'
    }`
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Monday publish routing live-verify step fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Monday publish routing live-verify step fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
