#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const workflowPath = path.resolve(__dirname, '../.github/workflows/weekly-growth-review.yml');
const stepName = 'Upsert founder first-48h post pack comment';
const marker = '<!-- weekly-growth-founder-first48h-post-pack -->';

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

function countMarkerComments(comments) {
  return comments.filter((comment) => String(comment.body || '').includes(marker)).length;
}

function createRunner(script) {
  const AsyncFunction = Object.getPrototypeOf(async function noop() {}).constructor;
  const executor = new AsyncFunction('github', 'context', 'core', 'process', 'require', script);

  return async function runScenario({ packBody, comments }) {
    const outputs = {};
    const infoMessages = [];
    const currentComments = Array.isArray(comments)
      ? comments.map((comment, index) => ({
          id: Number(comment.id || index + 1),
          body: String(comment.body || ''),
          html_url: comment.html_url || `https://example.local/comment/${Number(comment.id || index + 1)}`
        }))
      : [];
    let nextCommentId = currentComments.reduce((max, comment) => Math.max(max, Number(comment.id) || 0), 0) + 1;
    const callCounts = { createComment: 0, updateComment: 0 };

    const github = {
      rest: {
        issues: {
          listComments: async () => ({
            data: currentComments.map((comment) => ({ ...comment }))
          }),
          createComment: async ({ body }) => {
            callCounts.createComment += 1;
            const created = {
              id: nextCommentId,
              body: String(body || ''),
              html_url: `https://example.local/comment/${nextCommentId}`
            };
            nextCommentId += 1;
            currentComments.push(created);
            return { data: { ...created } };
          },
          updateComment: async ({ comment_id, body }) => {
            callCounts.updateComment += 1;
            const targetIndex = currentComments.findIndex(
              (comment) => String(comment.id) === String(comment_id)
            );
            assertCondition(targetIndex >= 0, `Cannot update missing comment #${comment_id}.`);
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
      }
    };

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'fluidreader-first48h-fixture-'));
    const packPath = path.join(tmpDir, 'founder-first48h-post-pack.md');
    fs.writeFileSync(packPath, String(packBody || ''), 'utf8');

    try {
      await executor(github, context, core, {
        env: {
          ISSUE_NUMBER: '17',
          FOUNDER_FIRST48H_POST_PACK_PATH: packPath
        }
      }, require);
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }

    return {
      outputs,
      infoMessages,
      comments: currentComments.map((comment) => ({ ...comment })),
      callCounts
    };
  };
}

async function runFixtureSuite() {
  const script = extractStepScript(workflowPath, stepName);
  const runScenario = createRunner(script);

  const createdBody = `${marker}

## Founder First 48h Post Pack

- Day 0: publish launch proof thread + CTA reply ladder.
- Day 1: ship objection teardown and proof follow-up.
- Day 2: post breakout recap and invite creators.
`;

  const createdScenario = await runScenario({
    packBody: createdBody,
    comments: [
      {
        id: 300,
        body: 'General planning note',
        html_url: 'https://example.local/comment/300'
      }
    ]
  });

  assertCondition(
    createdScenario.callCounts.createComment === 1 && createdScenario.callCounts.updateComment === 0,
    'Expected createComment call only when marker comment is absent.'
  );
  assertCondition(
    countMarkerComments(createdScenario.comments) === 1,
    'Expected one founder first-48h marker comment to be created.'
  );
  const createdMarkerComment = createdScenario.comments.find((comment) =>
    String(comment.body || '').includes(marker)
  );
  assertCondition(
    createdMarkerComment && createdMarkerComment.body === createdBody,
    'Expected created marker comment body to match generated founder first-48h artifact content.'
  );
  assertCondition(
    createdScenario.infoMessages.some((message) =>
      message.includes('Created founder first-48h post pack comment:')
    ),
    'Expected create log message for founder first-48h post pack comment.'
  );

  const updatedBody = `${marker}

## Founder First 48h Post Pack

- Day 0: publish new primary hook and FAQ replies.
- Day 1: capture testimonials and milestone clips.
- Day 2: schedule distribution handoff and reposts.
`;

  const updatedScenario = await runScenario({
    packBody: updatedBody,
    comments: [
      {
        id: 401,
        body: 'Non-marker note',
        html_url: 'https://example.local/comment/401'
      },
      {
        id: 402,
        body: `${marker}\nlegacy content`,
        html_url: 'https://example.local/comment/402'
      }
    ]
  });

  assertCondition(
    updatedScenario.callCounts.createComment === 0 && updatedScenario.callCounts.updateComment === 1,
    'Expected updateComment call only when a marker comment already exists.'
  );
  assertCondition(
    countMarkerComments(updatedScenario.comments) === 1,
    'Expected one founder first-48h marker comment after update.'
  );
  const updatedMarkerComment = updatedScenario.comments.find((comment) => Number(comment.id) === 402);
  assertCondition(
    updatedMarkerComment && updatedMarkerComment.body === updatedBody,
    'Expected existing marker comment body to be updated to latest founder first-48h artifact.'
  );
  assertCondition(
    updatedScenario.infoMessages.some((message) =>
      message.includes('Updated founder first-48h post pack comment:')
    ),
    'Expected update log message for founder first-48h post pack comment.'
  );
}

runFixtureSuite()
  .then(() => {
    process.stdout.write('Founder first-48h post pack fixture checks passed.\n');
  })
  .catch((error) => {
    process.stderr.write(`Founder first-48h post pack fixture checks failed: ${error.message}\n`);
    process.exit(1);
  });
