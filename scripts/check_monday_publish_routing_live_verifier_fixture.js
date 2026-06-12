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

function buildReviewBody({ primaryScript, backupScript }) {
  return `<!-- weekly-growth-review -->
# Weekly Growth Review

### Next-Week Channel Scripts

- Primary channel (\`X / Threads\`): Variant A

\`\`\`text
${primaryScript}
\`\`\`

- Backup channel (\`LinkedIn\`): Variant B

\`\`\`text
${backupScript}
\`\`\`

- Next-week variant recommendation: Keep proof-first route while monitoring reply quality.
`;
}

function buildChecklistBody({ includeROIAnnotation }) {
  const sourceAnnotations = includeROIAnnotation
    ? '[ROI lead: backup] [Narrative lead: Variant A]'
    : '[Narrative lead: Variant A]';

  return `<!-- weekly-growth-monday-publish-checklist -->
# Monday Publish Checklist: 2099-W44

## First 24-Hour Reply Effectiveness

- Channel ROI preferred channel: backup
- Founder narrative preferred variant: A
- Founder narrative routing action: promoted-backup-to-primary

## Default Publish Drafts (Auto-Promoted)

- Source review artifact: .build/growth/2099-W44-review.md ${sourceAnnotations}
- Primary default draft: X / Threads (Variant A)

\`\`\`text
LIVE REVIEW PRIMARY SCRIPT A
\`\`\`

- Backup default draft: LinkedIn (Variant B)

\`\`\`text
LIVE REVIEW BACKUP SCRIPT B
\`\`\`
`;
}

function createGhStubScript(stubPath) {
  const script = `#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "$@" >> "$GH_STUB_LOG_PATH"
if [[ "$#" -ge 3 && "$1" == "issue" && "$2" == "view" ]]; then
  cat "$GH_STUB_CHECKLIST_BODY_PATH"
  exit 0
fi
echo "Unsupported gh invocation in fixture: $*" >&2
exit 1
`;
  fs.writeFileSync(stubPath, script, 'utf8');
  fs.chmodSync(stubPath, 0o755);
}

function runScenario({ includeROIAnnotation, expectedExitCode, expectedResultLine, expectedCheckLineToken }) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-routing-live-verifier-fixture-'));
  const stubGhPath = path.join(tmpDir, 'gh');
  const ghLogPath = path.join(tmpDir, 'gh-log.txt');
  const reviewPath = path.join(tmpDir, 'review.md');
  const checklistPath = path.join(tmpDir, 'checklist.md');
  const outPath = path.join(tmpDir, 'routing-live-check.md');

  fs.writeFileSync(ghLogPath, '', 'utf8');
  fs.writeFileSync(
    reviewPath,
    buildReviewBody({
      primaryScript: 'LIVE REVIEW PRIMARY SCRIPT A',
      backupScript: 'LIVE REVIEW BACKUP SCRIPT B'
    }),
    'utf8'
  );
  fs.writeFileSync(checklistPath, buildChecklistBody({ includeROIAnnotation }), 'utf8');
  createGhStubScript(stubGhPath);

  const commandResult = spawnSync(
    '/bin/zsh',
    [
      verifierScriptPath,
      '--repo',
      'owner/repo',
      '--issue',
      '123',
      '--review',
      reviewPath,
      '--strict',
      '--out',
      outPath
    ],
    {
      cwd: workspaceRoot,
      env: {
        ...process.env,
        PATH: `${tmpDir}:${process.env.PATH || ''}`,
        GH_STUB_LOG_PATH: ghLogPath,
        GH_STUB_CHECKLIST_BODY_PATH: checklistPath
      },
      encoding: 'utf8'
    }
  );

  const status = Number(commandResult.status);
  assertCondition(
    status === expectedExitCode,
    `Expected verifier exit code ${expectedExitCode}, got ${status}. stderr=${String(commandResult.stderr || '')}`
  );
  assertCondition(fs.existsSync(outPath), `Expected verifier report output file: ${outPath}`);
  const outBody = fs.readFileSync(outPath, 'utf8');
  assertCondition(
    outBody.includes('- Mode: live'),
    `Expected live mode metadata in verifier report. output=${outBody}`
  );
  assertCondition(
    outBody.includes(expectedResultLine),
    `Expected verifier report result line "${expectedResultLine}".`
  );
  assertCondition(
    outBody.includes(expectedCheckLineToken),
    `Expected verifier report to include check token "${expectedCheckLineToken}".`
  );

  const ghLog = fs.readFileSync(ghLogPath, 'utf8');
  assertCondition(
    ghLog.includes('issue\nview\n123') || ghLog.includes('issue\nview\n123\n'),
    `Expected live verifier to invoke "gh issue view 123". log=${ghLog}`
  );
  assertCondition(
    ghLog.includes('--repo\nowner/repo'),
    `Expected live verifier gh call to include repo wiring. log=${ghLog}`
  );

  fs.rmSync(tmpDir, { recursive: true, force: true });
}

function runFixtureSuite() {
  runScenario({
    includeROIAnnotation: true,
    expectedExitCode: 0,
    expectedResultLine: '- Result: PASS',
    expectedCheckLineToken: '✅ ROI backup source annotation: source contains [ROI lead: backup]'
  });

  runScenario({
    includeROIAnnotation: false,
    expectedExitCode: 1,
    expectedResultLine: '- Result: FAIL',
    expectedCheckLineToken: '❌ ROI backup source annotation: missing [ROI lead: backup] annotation'
  });
}

try {
  runFixtureSuite();
  process.stdout.write('Monday publish routing live verifier fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Monday publish routing live verifier fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
