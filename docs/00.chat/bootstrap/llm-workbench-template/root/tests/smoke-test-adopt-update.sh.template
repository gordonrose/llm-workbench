#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_grep() {
  local pattern="$1"
  local path="$2"
  grep -Eq -- "$pattern" "$path" || fail "missing pattern '$pattern' in $path"
}

reject_grep() {
  local pattern="$1"
  local path="$2"
  if grep -Eq -- "$pattern" "$path"; then
    fail "unexpected pattern '$pattern' in $path"
  fi
}

WORKBENCH_REPO="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$WORKBENCH_REPO/bin/llm-workbench.js"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/llm-workbench-adopt-update.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init --quiet --initial-branch=main
  git -C "$repo" config user.name "llm-workbench adopt update smoke"
  git -C "$repo" config user.email "llm-workbench-adopt-update@example.invalid"
}

TARGET_REPO="$TMP_ROOT/target"
make_repo "$TARGET_REPO"

node "$CLI" init --target "$TARGET_REPO" > "$TMP_ROOT/init.out"
require_grep '^Wrote llm-workbench lock: \.llm-workbench/lock\.json$' "$TMP_ROOT/init.out"
require_grep '^Wrote llm-workbench manifest: \.llm-workbench/manifest\.json$' "$TMP_ROOT/init.out"
test -f "$TARGET_REPO/.llm-workbench/lock.json" || fail "install did not write lock.json"
test -f "$TARGET_REPO/.llm-workbench/manifest.json" || fail "install did not write manifest.json"

node "$CLI" update --target "$TARGET_REPO" --dry-run > "$TMP_ROOT/update-clean.out"
require_grep '^llm-workbench update dry-run$' "$TMP_ROOT/update-clean.out"
require_grep '^same: ' "$TMP_ROOT/update-clean.out"
require_grep '^conflicts: 0$' "$TMP_ROOT/update-clean.out"
require_grep '^No files changed\.$' "$TMP_ROOT/update-clean.out"

UPDATED_WORKBENCH="$TMP_ROOT/updated-workbench"
cp -R "$WORKBENCH_REPO" "$UPDATED_WORKBENCH"
node - "$UPDATED_WORKBENCH" <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const packagePath = path.join(root, 'package.json');
const manifest = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
manifest.version = '0.1.0-beta.2';
fs.writeFileSync(packagePath, `${JSON.stringify(manifest, null, 2)}\n`);
fs.appendFileSync(path.join(root, 'LLM_WORKBENCH.md'), '\nAdopt/update smoke forward change.\n');
NODE

node "$UPDATED_WORKBENCH/bin/llm-workbench.js" update --target "$TARGET_REPO" --dry-run \
  > "$TMP_ROOT/update-forward-dry-run.out"
require_grep '^Current version: 0\.1\.0-beta\.1$' "$TMP_ROOT/update-forward-dry-run.out"
require_grep '^Target version: 0\.1\.0-beta\.2$' "$TMP_ROOT/update-forward-dry-run.out"
require_grep '^UPDATE LLM_WORKBENCH\.md$' "$TMP_ROOT/update-forward-dry-run.out"
require_grep '^conflicts: 0$' "$TMP_ROOT/update-forward-dry-run.out"
require_grep '^No files changed\.$' "$TMP_ROOT/update-forward-dry-run.out"
reject_grep 'Adopt/update smoke forward change\.' "$TARGET_REPO/LLM_WORKBENCH.md"

node "$UPDATED_WORKBENCH/bin/llm-workbench.js" update --target "$TARGET_REPO" --apply \
  > "$TMP_ROOT/update-forward-apply.out"
require_grep '^Update apply completed\.$' "$TMP_ROOT/update-forward-apply.out"
require_grep 'Adopt/update smoke forward change\.' "$TARGET_REPO/LLM_WORKBENCH.md"
node - "$TARGET_REPO/.llm-workbench/lock.json" <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (lock.version !== '0.1.0-beta.2') {
  throw new Error(`expected updated lock version, got ${lock.version}`);
}
NODE

node "$CLI" update --target "$TARGET_REPO" --dry-run > "$TMP_ROOT/rollback-dry-run.out"
require_grep '^Current version: 0\.1\.0-beta\.2$' "$TMP_ROOT/rollback-dry-run.out"
require_grep '^Target version: 0\.1\.0-beta\.1$' "$TMP_ROOT/rollback-dry-run.out"
require_grep '^UPDATE LLM_WORKBENCH\.md$' "$TMP_ROOT/rollback-dry-run.out"
require_grep '^conflicts: 0$' "$TMP_ROOT/rollback-dry-run.out"

node "$CLI" update --target "$TARGET_REPO" --apply > "$TMP_ROOT/rollback-apply.out"
require_grep '^Update apply completed\.$' "$TMP_ROOT/rollback-apply.out"
reject_grep 'Adopt/update smoke forward change\.' "$TARGET_REPO/LLM_WORKBENCH.md"
node - "$TARGET_REPO/.llm-workbench/lock.json" <<'NODE'
const fs = require('fs');
const lock = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (lock.version !== '0.1.0-beta.1') {
  throw new Error(`expected rollback lock version, got ${lock.version}`);
}
NODE

printf '\nlocal unmanaged edit\n' >> "$TARGET_REPO/LLM_WORKBENCH.md"
if node "$UPDATED_WORKBENCH/bin/llm-workbench.js" update --target "$TARGET_REPO" --apply \
  > "$TMP_ROOT/update-conflict.out" 2>&1; then
  fail "update apply unexpectedly overwrote a locally edited managed file"
fi
require_grep '^CONFLICT LLM_WORKBENCH\.md$' "$TMP_ROOT/update-conflict.out"
require_grep 'plan has conflicts or missing managed material; apply refused' "$TMP_ROOT/update-conflict.out"

ADOPT_REPO="$TMP_ROOT/adopt-target"
make_repo "$ADOPT_REPO"
mkdir -p "$ADOPT_REPO/scripts/00.chat/worktree/check-write-location"
cp "$WORKBENCH_REPO/scripts/00.chat/worktree/check-write-location/script.sh" \
  "$ADOPT_REPO/scripts/00.chat/worktree/check-write-location/script.sh"
mkdir -p "$ADOPT_REPO/src" "$ADOPT_REPO/commitLogs/keep"
printf '# Existing rules\n\nKeep this project-specific rule.\n' > "$ADOPT_REPO/AGENTS.md"
printf 'product code\n' > "$ADOPT_REPO/src/product.txt"
printf 'session log\n' > "$ADOPT_REPO/commitLogs/keep/README.md"
cat > "$ADOPT_REPO/package.json" <<'JSON'
{
  "name": "adopt-target",
  "scripts": {
    "build": "echo build"
  }
}
JSON

node "$CLI" adopt --target "$ADOPT_REPO" --dry-run > "$TMP_ROOT/adopt-dry-run.out"
require_grep '^ADOPT scripts/00\.chat/worktree/check-write-location/script\.sh$' "$TMP_ROOT/adopt-dry-run.out"
require_grep '^PATCH_BLOCK AGENTS\.md$' "$TMP_ROOT/adopt-dry-run.out"
require_grep '^LOCAL_ONLY src/product\.txt$' "$TMP_ROOT/adopt-dry-run.out"
reject_grep '^LOCAL_ONLY \.git/' "$TMP_ROOT/adopt-dry-run.out"
reject_grep '^LOCAL_ONLY commitLogs/' "$TMP_ROOT/adopt-dry-run.out"
require_grep '^No files changed\.$' "$TMP_ROOT/adopt-dry-run.out"
test ! -e "$ADOPT_REPO/.llm-workbench/manifest.json" || fail "adopt dry-run wrote manifest"

node "$CLI" adopt --target "$ADOPT_REPO" --apply > "$TMP_ROOT/adopt-apply.out"
require_grep '^Adopt apply completed\.$' "$TMP_ROOT/adopt-apply.out"
require_grep 'llm-workbench:start' "$ADOPT_REPO/AGENTS.md"
test -f "$ADOPT_REPO/.llm-workbench/lock.json" || fail "adopt apply did not write lock"
test -f "$ADOPT_REPO/.llm-workbench/manifest.json" || fail "adopt apply did not write manifest"
test -f "$ADOPT_REPO/src/product.txt" || fail "adopt apply removed local product file"
test -f "$ADOPT_REPO/commitLogs/keep/README.md" || fail "adopt apply removed commit log"

echo "llm-wb adopt/update smoke test passed."
