#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Generate Monday draft from highlight plan';
const marker = '<!-- weekly-growth-monday-draft -->';

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

function buildHighlightIssueBody() {
  return `# Growth Highlight Plan

- Win Card copies: 12
- Win Recap copies: 9
- Public posts shipped: 4
- User-generated stories: 3
- Inbound installs/trials: 6
`;
}

function buildReviewBody({ primaryScript, backupScript }) {
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
`;
}

function findMarkerComment(comments) {
  return comments.find((comment) => String(comment.body || '').includes(marker));
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', 'require', script);

  return async function runScenario({ reviewBody, comments }) {
    const outputs = {};
    const infoMessages = [];
    const callCounts = { get: 0, listComments: 0, createComment: 0, updateComment: 0 };
    const currentComments = Array.isArray(comments)
      ? comments.map((comment, index) => ({
          id: Number(comment.id || index + 1),
          body: String(comment.body || ''),
          html_url: comment.html_url || `https://example.local/comment/${Number(comment.id || index + 1)}`
        }))
      : [];
    let nextCommentID = currentComments.reduce((max, comment) => Math.max(max, Number(comment.id) || 0), 0) + 1;

    const github = {
      rest: {
        issues: {
          get: async () => {
            callCounts.get += 1;
            return { data: { body: buildHighlightIssueBody() } };
          },
          listComments: async () => {
            callCounts.listComments += 1;
            return { data: currentComments.map((comment) => ({ ...comment })) };
          },
          createComment: async ({ body }) => {
            callCounts.createComment += 1;
            const created = {
              id: nextCommentID,
              body: String(body || ''),
              html_url: `https://example.local/comment/${nextCommentID}`
            };
            nextCommentID += 1;
            currentComments.push(created);
            return { data: { ...created } };
          },
          updateComment: async ({ comment_id, body }) => {
            callCounts.updateComment += 1;
            const targetIndex = currentComments.findIndex(
              (comment) => String(comment.id) === String(comment_id)
            );
            assertCondition(targetIndex >= 0, `Cannot update missing Monday draft comment #${comment_id}.`);
            currentComments[targetIndex] = {
              ...currentComments[targetIndex],
              body: String(body || '')
            };
            return { data: { ...currentComments[targetIndex] } };
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

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-monday-draft-fixture-'));
    const reviewPath = path.join(tmpDir, 'weekly-review.md');
    fs.writeFileSync(reviewPath, String(reviewBody || ''), 'utf8');

    let mondayDraftBody = '';
    try {
      await executor(github, context, core, {
        env: {
          HIGHLIGHT_PLAN_ISSUE_NUMBER: '17',
          WEEK: '2099-W02',
          METRIC_FOCUS: 'Win Card copies and reply quality',
          REVIEW_PATH: reviewPath,
          PRIMARY_CHANNEL: 'X / Threads',
          BACKUP_CHANNEL: 'LinkedIn'
        }
      }, require);

      const mondayDraftPath = String(outputs.monday_draft_path || '');
      assertCondition(mondayDraftPath.length > 0, 'Expected Monday draft path output to be set.');
      assertCondition(fs.existsSync(mondayDraftPath), `Expected Monday draft artifact to exist: ${mondayDraftPath}`);
      mondayDraftBody = fs.readFileSync(mondayDraftPath, 'utf8');
      fs.rmSync(mondayDraftPath, { force: true });
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }

    return {
      outputs,
      infoMessages,
      callCounts,
      comments: currentComments.map((comment) => ({ ...comment })),
      mondayDraftBody,
      reviewPath
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const createdScenario = await runScenario({
    reviewBody: buildReviewBody({
      primaryScript: 'PROMOTED PRIMARY SCRIPT FROM REVIEW',
      backupScript: 'PROMOTED BACKUP SCRIPT FROM REVIEW'
    }),
    comments: [
      {
        id: 700,
        body: 'General note',
        html_url: 'https://example.local/comment/700'
      }
    ]
  });

  assertCondition(
    createdScenario.callCounts.createComment === 1 && createdScenario.callCounts.updateComment === 0,
    'Expected Monday draft comment create path when marker comment is absent.'
  );
  assertCondition(
    createdScenario.outputs.default_source_label === createdScenario.reviewPath,
    'Expected Monday draft default source label to resolve to review artifact path.'
  );
  assertCondition(
    createdScenario.outputs.default_primary_variant === 'A' &&
      createdScenario.outputs.default_backup_variant === 'B',
    'Expected Monday draft default variants promoted from review scripts.'
  );
  assertCondition(
    createdScenario.mondayDraftBody.includes('PROMOTED PRIMARY SCRIPT FROM REVIEW') &&
      createdScenario.mondayDraftBody.includes('PROMOTED BACKUP SCRIPT FROM REVIEW'),
    'Expected Monday draft artifact to include promoted review scripts.'
  );
  const createdMarkerComment = findMarkerComment(createdScenario.comments);
  assertCondition(
    createdMarkerComment &&
      createdMarkerComment.body.includes('PROMOTED PRIMARY SCRIPT FROM REVIEW') &&
      createdMarkerComment.body.includes('PROMOTED BACKUP SCRIPT FROM REVIEW'),
    'Expected created Monday draft comment body to include promoted review scripts.'
  );

  const updatedScenario = await runScenario({
    reviewBody: buildReviewBody({
      primaryScript: 'UPDATED PRIMARY SCRIPT FROM REVIEW',
      backupScript: 'UPDATED BACKUP SCRIPT FROM REVIEW'
    }),
    comments: [
      {
        id: 801,
        body: `${marker}\nlegacy monday draft content`,
        html_url: 'https://example.local/comment/801'
      }
    ]
  });

  assertCondition(
    updatedScenario.callCounts.createComment === 0 && updatedScenario.callCounts.updateComment === 1,
    'Expected Monday draft comment update path when marker comment exists.'
  );
  const updatedMarkerComment = findMarkerComment(updatedScenario.comments);
  assertCondition(
    updatedMarkerComment &&
      updatedMarkerComment.body.includes('UPDATED PRIMARY SCRIPT FROM REVIEW') &&
      updatedMarkerComment.body.includes('UPDATED BACKUP SCRIPT FROM REVIEW'),
    'Expected updated Monday draft marker comment body to use latest promoted review scripts.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Monday draft promoted-scripts fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Monday draft promoted-scripts fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
