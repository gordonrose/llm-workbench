#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

WORKBENCH_REPO="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$WORKBENCH_REPO/bin/llm-workbench.js"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/llm-workbench-cli.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

TARGET_REPO="$TMP_ROOT/target"
mkdir -p "$TARGET_REPO"
git -C "$TARGET_REPO" init --quiet --initial-branch=main
git -C "$TARGET_REPO" config user.name "llm-workbench cli smoke"
git -C "$TARGET_REPO" config user.email "llm-workbench-cli-smoke@example.invalid"

node "$CLI" --help > "$TMP_ROOT/help.out"
grep -q '^llm-wb$' "$TMP_ROOT/help.out" || fail "help did not print short command name"
grep -q '^Usage:' "$TMP_ROOT/help.out" || fail "help did not print usage"
grep -q '^  init ' "$TMP_ROOT/help.out" || fail "help did not list init"
grep -q '^  adopt ' "$TMP_ROOT/help.out" || fail "help did not list adopt"
grep -q '^  update ' "$TMP_ROOT/help.out" || fail "help did not list update"
grep -q '^  new ' "$TMP_ROOT/help.out" || fail "help did not list new"
grep -q '^  sessions list ' "$TMP_ROOT/help.out" || fail "help did not list sessions list"
grep -q '^  commit ' "$TMP_ROOT/help.out" || fail "help did not list commit"
grep -q '^  merge-main ' "$TMP_ROOT/help.out" || fail "help did not list merge-main"

npm pack --dry-run --json --cache "$TMP_ROOT/npm-cache" > "$TMP_ROOT/pack.json"
node - "$TMP_ROOT/pack.json" "$WORKBENCH_REPO/package.json" <<'NODE'
const fs = require('fs');
const packPath = process.argv[2];
const packagePath = process.argv[3];
const [pack] = JSON.parse(fs.readFileSync(packPath, 'utf8'));
const manifest = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const files = new Set(pack.files.map((file) => file.path));
if (manifest.name !== 'llm-wb') {
  throw new Error(`unexpected package name: ${manifest.name}`);
}
if (manifest.version !== '0.1.0-beta.3') {
  throw new Error(`unexpected package version: ${manifest.version}`);
}
if (Object.prototype.hasOwnProperty.call(manifest, 'private')) {
  throw new Error('package still has private metadata');
}
if (!manifest.bin || Object.keys(manifest.bin).length !== 1 || manifest.bin['llm-wb'] !== 'bin/llm-workbench.js') {
  throw new Error('package must publish only the llm-wb bin mapping');
}
if (manifest.license !== 'MIT') {
  throw new Error(`unexpected package license: ${manifest.license}`);
}
if (!manifest.repository || manifest.repository.url !== 'git+https://github.com/gordonrose/llm-workbench.git') {
  throw new Error('missing npm repository metadata');
}
if (!manifest.bugs || manifest.bugs.url !== 'https://github.com/gordonrose/llm-workbench/issues') {
  throw new Error('missing npm bugs metadata');
}
if (!manifest.homepage || manifest.homepage !== 'https://github.com/gordonrose/llm-workbench#readme') {
  throw new Error('missing npm homepage metadata');
}
if (!manifest.engines || manifest.engines.node !== '>=18') {
  throw new Error('missing supported Node.js engine metadata');
}
if (!manifest.publishConfig || manifest.publishConfig.access !== 'public' || Object.prototype.hasOwnProperty.call(manifest.publishConfig, 'tag')) {
  throw new Error('package publish metadata must publish publicly without requiring a non-default dist-tag');
}

function requireFile(path) {
  if (!files.has(path)) {
    throw new Error(`missing package file: ${path}`);
  }
}

function rejectPrefix(prefix) {
  for (const file of files) {
    if (file.startsWith(prefix)) {
      throw new Error(`unexpected package file: ${file}`);
    }
  }
}

requireFile('bin/llm-workbench.js');
requireFile('bin/llm-workbench-ownership.js');
requireFile('scripts/install.sh');
requireFile('scripts/00.chat/command/dispatcher/script.sh');
requireFile('scripts/00.chat/command/download-repo/script.sh');
requireFile('scripts/00.chat/command/download-repo-diff/script.sh');
requireFile('scripts/00.chat/export/create-worktree-bundle/script.js');
requireFile('scripts/00.chat/export/worktree/script.sh');
requireFile('scripts/00.chat/export/worktree-diff/script.sh');
requireFile('scripts/00.chat/session-log/record-chat-commit/script.sh');
requireFile('scripts/00.chat/local-merge/list-active-chat-branches/script.sh');
requireFile('scripts/00.chat/local-merge/verify-chat-ready-to-merge-local-main/script.sh');
requireFile('scripts/01.harness/run-governed-script.sh');
requireFile('tests/smoke-test-adopt-update.sh');
rejectPrefix('commitLogs/');
rejectPrefix('docs/00.chat/bootstrap/');
rejectPrefix('scripts/00.chat/upstream/');
rejectPrefix('tests/smoke-test-cli.sh');
NODE

if node "$CLI" nope > "$TMP_ROOT/unknown.out" 2>&1; then
  fail "unknown command unexpectedly succeeded"
fi
grep -q '^ERROR: unknown command: nope$' "$TMP_ROOT/unknown.out" || fail "unknown command error was unclear"

NON_REPO="$TMP_ROOT/not-a-repo"
mkdir -p "$NON_REPO"
if node "$CLI" init --target "$NON_REPO" --dry-run > "$TMP_ROOT/non-repo.out" 2>&1; then
  fail "init into non-git directory unexpectedly succeeded"
fi
grep -q '^ERROR: target repo is not a git repo: ' "$TMP_ROOT/non-repo.out" || fail "non-git target error was unclear"

if (cd "$TARGET_REPO" && node "$CLI" list) > "$TMP_ROOT/not-installed.out" 2>&1; then
  fail "list before install unexpectedly succeeded"
fi
grep -q '^ERROR: llm-workbench install has not been run in this repo: ' "$TMP_ROOT/not-installed.out" || fail "missing install error was unclear"

node "$CLI" init --dry-run --target "$TARGET_REPO" > "$TMP_ROOT/init-dry-run.out"
grep -q '^mode: dry-run$' "$TMP_ROOT/init-dry-run.out" || fail "init dry-run did not call installer dry-run"
test ! -e "$TARGET_REPO/.llm-workbench/install-manifest.tsv" || fail "dry-run wrote install manifest"
test ! -e "$TARGET_REPO/.llm-workbench/lock.json" || fail "dry-run wrote lock"
test ! -e "$TARGET_REPO/.llm-workbench/manifest.json" || fail "dry-run wrote manifest"

node "$CLI" init --target "$TARGET_REPO" > "$TMP_ROOT/init-apply.out"
grep -q '^mode: apply$' "$TMP_ROOT/init-apply.out" || fail "init apply did not call installer apply"
test -f "$TARGET_REPO/.llm-workbench/install-manifest.tsv" || fail "apply did not write install manifest"
test -f "$TARGET_REPO/.llm-workbench/lock.json" || fail "apply did not write lock"
test -f "$TARGET_REPO/.llm-workbench/manifest.json" || fail "apply did not write manifest"

(
  cd "$TARGET_REPO"
  node "$CLI" list > "$TMP_ROOT/list.out"
)
grep -q '^  new$' "$TMP_ROOT/list.out" || fail "list did not delegate to chat:list"
if (cd "$TARGET_REPO" && node "$CLI" list list) > "$TMP_ROOT/list-extra.out" 2>&1; then
  fail "list with extra argument unexpectedly succeeded"
fi
grep -q '^ERROR: list does not accept arguments$' "$TMP_ROOT/list-extra.out" || fail "list extra argument error was unclear"

git -C "$TARGET_REPO" add -A
git -C "$TARGET_REPO" commit --quiet -m "Install llm-workbench harness"

(
  cd "$TARGET_REPO"
  AGENTIC_CHAT_WORKTREE_ROOT="$TMP_ROOT/worktrees" \
  CHAT_CLEANUP_EMPTY_BRANCHES=skip \
  CHAT_COPY_PROMPT=skip \
  CHAT_OPEN_WORKTREE_WINDOW=skip \
    node "$CLI" new "cli smoke first chat startup" > "$TMP_ROOT/new.out"
)

grep -q 'Created branch: chat/' "$TMP_ROOT/new.out" || fail "new did not delegate to chat:new"
find "$TMP_ROOT/worktrees" -path '*/commitLogs/*/README.md' -type f | grep -q . || fail "new did not create a chat worktree log"

CHAT_BRANCH="$(git -C "$TARGET_REPO" branch --format='%(refname:short)' | grep '^chat/' | head -n 1)"
CHAT_WORKTREE="$(
  git -C "$TARGET_REPO" worktree list --porcelain \
    | awk -v branch="refs/heads/${CHAT_BRANCH}" '
      /^worktree / { path = substr($0, 10) }
      /^branch / && substr($0, 8) == branch { print path }
    '
)"

test -n "$CHAT_BRANCH" || fail "new did not create a chat branch"
test -n "$CHAT_WORKTREE" || fail "new did not create a chat worktree"

CHAT_LOG="$(find "$CHAT_WORKTREE/commitLogs" -path '*/README.md' -type f | head -n 1)"
test -f "$CHAT_LOG" || fail "chat log not found in chat worktree"

node - "$CHAT_LOG" <<'NODE'
const fs = require('fs');
const logPath = process.argv[2];
let text = fs.readFileSync(logPath, 'utf8');
text = text.replace(
  '## Decisions Made\n\n- None recorded yet.',
  '## Decisions Made\n\n- CLI smoke recorded that this commit is safe to test.'
);
text = text.replace('ADR needed: unknown', 'ADR needed: no');
text = text.replace('Reason:\n', 'Reason: CLI smoke change does not make a durable architecture decision.\n');
fs.writeFileSync(logPath, text);
NODE

printf 'cli smoke task work\n' > "$CHAT_WORKTREE/cli-smoke-task.txt"

(
  cd "$CHAT_WORKTREE"
  AGENTIC_CHAT_WORKTREE_ROOT="$TMP_ROOT/worktrees" \
    node "$CLI" commit -m "CLI smoke task commit" --summary "Commit CLI smoke task work" \
    > "$TMP_ROOT/commit.out"
)

grep -q '^Committed chat task work: ' "$TMP_ROOT/commit.out" || fail "commit did not report committed task work"
grep -q '^Recorded chat commit: ' "$TMP_ROOT/commit.out" || fail "commit did not record the task commit"
grep -q '^Checkpointed chat session bookkeeping:' "$TMP_ROOT/commit.out" || fail "commit did not checkpoint session bookkeeping"
test -z "$(git -C "$CHAT_WORKTREE" status --porcelain)" || fail "chat worktree was not clean after commit"
git -C "$CHAT_WORKTREE" log --format=%s -2 > "$TMP_ROOT/chat-log-subjects.out"
grep -q '^chore(session): checkpoint ' "$TMP_ROOT/chat-log-subjects.out" || fail "checkpoint commit missing"
grep -q '^CLI smoke task commit$' "$TMP_ROOT/chat-log-subjects.out" || fail "task commit missing"

(
  cd "$CHAT_WORKTREE"
  AGENTIC_CHAT_WORKTREE_ROOT="$TMP_ROOT/worktrees" \
    node "$CLI" sessions list > "$TMP_ROOT/sessions-list.out"
)
grep -q '^branch	relation	behind	ahead	layer	mode	status	task$' "$TMP_ROOT/sessions-list.out" || fail "sessions list did not print session header"
grep -q "$CHAT_BRANCH" "$TMP_ROOT/sessions-list.out" || fail "sessions list did not include chat branch"
grep -q 'cli smoke first chat startup' "$TMP_ROOT/sessions-list.out" || fail "sessions list did not include session task"

if ! (
  cd "$CHAT_WORKTREE"
  AGENTIC_CHAT_WORKTREE_ROOT="$TMP_ROOT/worktrees" \
    node "$CLI" merge-main > "$TMP_ROOT/merge-main.out" 2>&1
); then
  cat "$TMP_ROOT/merge-main.out" >&2
  git -C "$TARGET_REPO" status --short >&2 || true
  fail "merge-main command failed"
fi

grep -q '^State: eligible$' "$TMP_ROOT/merge-main.out" || fail "merge-main did not run readiness verification"
grep -q "^Merged ${CHAT_BRANCH} into local main\\.$" "$TMP_ROOT/merge-main.out" || fail "merge-main did not report local merge"
grep -q '^No remote push was performed\.$' "$TMP_ROOT/merge-main.out" || fail "merge-main did not preserve push boundary"
test -f "$TARGET_REPO/cli-smoke-task.txt" || fail "merge-main did not bring task file to main"
test -z "$(git -C "$TARGET_REPO" status --porcelain)" || fail "root worktree was dirty after merge-main"

BROKEN_REPO="$TMP_ROOT/broken"
cp -R "$TARGET_REPO" "$BROKEN_REPO"
rm "$BROKEN_REPO/scripts/00.chat/command/dispatcher/script.sh"

if (cd "$BROKEN_REPO" && node "$CLI" list) > "$TMP_ROOT/missing-script.out" 2>&1; then
  fail "list with missing dispatcher unexpectedly succeeded"
fi
grep -q '^ERROR: required llm-workbench scripts are missing:' "$TMP_ROOT/missing-script.out" || fail "missing script error was unclear"

echo "llm-wb CLI smoke test passed."
