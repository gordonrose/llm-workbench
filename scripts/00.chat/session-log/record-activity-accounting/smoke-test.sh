#!/usr/bin/env bash
set -euo pipefail

# agentic-artifact:
#   schema: agentic-artifact/v2
#   id: chat.script.session-log.record-activity-accounting.smoke-test
#   version: 1
#   status: active
#   layer: 00.chat
#   domain: session-log
#   disciplines:
#   - agentic
#   kind: script
#   purpose: Smoke test activity-accounting recording in chat session logs.
#   portability:
#     class: reusable
#     targets:
#     - llm-workbench
#   used_by:
#   - id: chat.script.session-log.record-activity-accounting
#     path: scripts/00.chat/session-log/record-activity-accounting/script.sh
#   - id: chat.script.session-log.record-activity-accounting.readme
#     path: scripts/00.chat/session-log/record-activity-accounting/README.md
#   effects:
#   - writes-files
#   - branches
#   - commits

fail() { echo "FAIL: $*" >&2; exit 1; }

SOURCE_ROOT="$(git rev-parse --show-toplevel)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/record-activity-accounting-smoke.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
REPO="$TMP_ROOT/repo"
SESSION_ID="2026-10-30-08-31-activity-accounting"
LOG_FILE="commitLogs/2026/oct/30/$SESSION_ID/README.md"

mkdir -p "$REPO/scripts/00.chat/session-log/paths" "$REPO/scripts/00.chat/session-log/record-activity-accounting" "$REPO/${LOG_FILE%/README.md}"
cp "$SOURCE_ROOT/scripts/00.chat/session-log/paths/lib.sh" "$REPO/scripts/00.chat/session-log/paths/lib.sh"
cp "$SOURCE_ROOT/scripts/00.chat/session-log/record-activity-accounting/script.sh" "$REPO/scripts/00.chat/session-log/record-activity-accounting/script.sh"
chmod +x "$REPO/scripts/00.chat/session-log/record-activity-accounting/script.sh"
cat > "$REPO/$LOG_FILE" <<EOF
# Chat Session: activity accounting

<!-- agentic-session
id: $SESSION_ID
branch: chat/$SESSION_ID
raised_at_utc: 2026-10-30T08:31:00Z
-->

## Activity Log

- None recorded yet.
EOF
git -C "$REPO" init -q
git -C "$REPO" add .
git -C "$REPO" -c user.name='Smoke Test' -c user.email='smoke@example.invalid' commit -qm base
git -C "$REPO" switch -qc "chat/$SESSION_ID"

run() { ( cd "$REPO" && bash scripts/00.chat/session-log/record-activity-accounting/script.sh "$@" ); }

run --slice 'small read-only review' --phase planning-inspection --status completed \
  --observed-at-utc 2026-10-30T08:32:00Z --interval-start-utc 2026-10-30T08:31:00Z --interval-end-utc 2026-10-30T08:32:00Z \
  --slice-elapsed-seconds 60 --summary 'Read the lifecycle owner.' --assessment 'The existing owner was sufficient; no change recommended.'

run --slice 'implementation slice' --phase implementation --status completed \
  --observed-at-utc 2026-10-30T08:40:00Z --interval-start-utc 2026-10-30T08:32:00Z --interval-end-utc 2026-10-30T08:40:00Z \
  --summary 'Parent consolidated a sub-agent handoff.' --assessment 'Overlap is disclosed, so child time is not added to wall time.' \
  --concurrent-with 'sub-agent review, 2026-10-30T08:34:00Z–2026-10-30T08:39:00Z' --continuation

run --slice 'verification correction' --phase correction --status completed \
  --observed-at-utc 2026-10-30T08:50:00Z --interval-start-utc 2026-10-30T08:40:00Z --interval-end-utc 2026-10-30T08:50:00Z \
  --summary 'Corrected a fixture after a failed focused proof.' --assessment 'Fixture setup caused rework; keep the regression.' \
  --issue-class known-repeat --problem 'Focused fixture failed.' --cause 'Supported fixture setup mismatch.' \
  --correction 'Corrected fixture setup.' --repeated-proof 'Focused receipt report/focused.json passed.' --responsible-role parent

run --slice 'verification reuse' --phase verification --status completed \
  --observed-at-utc 2026-10-30T09:00:00Z --measurement-status unavailable --unavailable-reason 'The trusted runner report has no command timing.' \
  --summary 'Reused matching focused receipt.' --assessment 'Reuse avoided a duplicate suite; duration remains unavailable.' \
  --verification reused --evidence-ref 'runner/latest-report.json'

if ! grep -q '^## Activity Accounting$' "$REPO/$LOG_FILE"; then fail 'legacy log did not gain activity section'; fi
if ! grep -q 'Continuation: yes' "$REPO/$LOG_FILE"; then fail 'continuation was not preserved'; fi
if ! grep -q 'Wall-time rule: concurrent intervals are not added' "$REPO/$LOG_FILE"; then fail 'overlap rule was not recorded'; fi
if ! grep -q 'Issue class: known-repeat' "$REPO/$LOG_FILE"; then fail 'known repeat was not recorded'; fi
if ! grep -q 'Unavailable measurement: The trusted runner report has no command timing.' "$REPO/$LOG_FILE"; then fail 'unavailable timing was not explicit'; fi
if ! grep -q 'Verification: reused' "$REPO/$LOG_FILE"; then fail 'verification reuse was not recorded'; fi

set +e
run --slice bad --phase verification --status completed --observed-at-utc 2026-10-30T09:01:00Z \
  --interval-start-utc 2026-10-30T09:00:00Z --interval-end-utc 2026-10-30T09:01:00Z \
  --summary bad --assessment bad --verification reused --evidence-ref runner/report --command-id focused --command-duration-seconds 2 >"$TMP_ROOT/reuse.out" 2>"$TMP_ROOT/reuse.err"
REUSE_STATUS=$?
run --slice bad --phase correction --status completed --observed-at-utc 2026-10-30T09:01:00Z \
  --interval-start-utc 2026-10-30T09:00:00Z --interval-end-utc 2026-10-30T09:01:00Z \
  --summary bad --assessment bad >"$TMP_ROOT/correction.out" 2>"$TMP_ROOT/correction.err"
CORRECTION_STATUS=$?
run --slice bad --phase review --status completed --observed-at-utc 2026-10-30T09:01:00Z \
  --interval-start-utc 2026-10-30T09:00:00Z --interval-end-utc 2026-10-30T09:01:00Z \
  --summary 'token=not-safe' --assessment bad >"$TMP_ROOT/sensitive.out" 2>"$TMP_ROOT/sensitive.err"
SENSITIVE_STATUS=$?
set -e
if [ "$REUSE_STATUS" -eq 0 ] || ! grep -q 'cannot claim a new command duration' "$TMP_ROOT/reuse.err"; then fail 'reused verification accepted a rerun duration'; fi
if [ "$CORRECTION_STATUS" -eq 0 ] || ! grep -q 'requires --correction and --repeated-proof' "$TMP_ROOT/correction.err"; then fail 'completed correction lacked proof guard'; fi
if [ "$SENSITIVE_STATUS" -eq 0 ] || ! grep -q 'do not record secrets' "$TMP_ROOT/sensitive.err"; then fail 'sensitive summary was accepted'; fi

echo 'record activity accounting smoke test passed.'
