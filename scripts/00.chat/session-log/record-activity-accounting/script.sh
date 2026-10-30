#!/usr/bin/env bash
set -euo pipefail

# agentic-artifact:
#   schema: agentic-artifact/v2
#   id: chat.script.session-log.record-activity-accounting
#   version: 1
#   status: active
#   layer: 00.chat
#   domain: session-log
#   disciplines:
#   - agentic
#   kind: script
#   purpose: Record bounded activity and efficiency evidence in the current session README.
#   portability:
#     class: required
#     targets:
#     - llm-workbench
#   used_by:
#   - id: chat.script.session-log.record-activity-accounting.readme
#     path: scripts/00.chat/session-log/record-activity-accounting/README.md
#   - id: chat.script.session-log.record-activity-accounting.smoke-test
#     path: scripts/00.chat/session-log/record-activity-accounting/smoke-test.sh
#   effects:
#   - writes-files

# shellcheck source=../paths/lib.sh
source "scripts/00.chat/session-log/paths/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  record-activity-accounting.sh \
    --slice <name> \
    --phase <planning-inspection|implementation|review|verification|correction|waiting|handoff-bookkeeping> \
    --status <started|completed|interrupted|failed> \
    --observed-at-utc <RFC3339-UTC> \
    --summary <safe summary> \
    --assessment <evidence-backed assessment> \
    [--interval-start-utc <RFC3339-UTC> --interval-end-utc <RFC3339-UTC>] \
    [--session-elapsed-seconds <non-negative-seconds>] \
    [--slice-elapsed-seconds <non-negative-seconds>] \
    [--command-id <safe command identifier> --command-duration-seconds <non-negative-seconds>] \
    [--verification <executed|reused|deferred|not-applicable>] \
    [--evidence-ref <safe report or receipt reference>] \
    [--concurrent-with <parent/sub-agent overlap description>] \
    [--waiting-seconds <non-negative-seconds>] \
    [--measurement-status <measured|unavailable> --unavailable-reason <reason>] \
    [--issue-class <none|new|known-repeat|hypothesis>] \
    [--problem <observed problem>] [--cause <supported cause or hypothesis>] \
    [--correction <correction>] [--repeated-proof <proof after correction>] \
    [--responsible-role <role when established>] [--continuation]

Appends one parent-owned activity-accounting entry to the current session README.
It does not run verification, infer durations from polling, stage, commit, or
change any verification receipt.
EOF
}

SLICE=""; PHASE=""; STATUS=""; OBSERVED_AT=""; SUMMARY=""; ASSESSMENT=""
INTERVAL_START=""; INTERVAL_END=""; SESSION_ELAPSED=""; SLICE_ELAPSED=""
COMMAND_ID=""; COMMAND_DURATION=""; VERIFICATION="not-applicable"; EVIDENCE_REF=""
CONCURRENT_WITH=""; WAITING_SECONDS=""; MEASUREMENT_STATUS="measured"
UNAVAILABLE_REASON=""; ISSUE_CLASS="none"; PROBLEM=""; CAUSE=""; CORRECTION=""
REPEATED_PROOF=""; RESPONSIBLE_ROLE=""; CONTINUATION="no"

while [ $# -gt 0 ]; do
  case "$1" in
    --slice) SLICE="${2:-}"; shift 2 ;;
    --phase) PHASE="${2:-}"; shift 2 ;;
    --status) STATUS="${2:-}"; shift 2 ;;
    --observed-at-utc) OBSERVED_AT="${2:-}"; shift 2 ;;
    --summary) SUMMARY="${2:-}"; shift 2 ;;
    --assessment) ASSESSMENT="${2:-}"; shift 2 ;;
    --interval-start-utc) INTERVAL_START="${2:-}"; shift 2 ;;
    --interval-end-utc) INTERVAL_END="${2:-}"; shift 2 ;;
    --session-elapsed-seconds) SESSION_ELAPSED="${2:-}"; shift 2 ;;
    --slice-elapsed-seconds) SLICE_ELAPSED="${2:-}"; shift 2 ;;
    --command-id) COMMAND_ID="${2:-}"; shift 2 ;;
    --command-duration-seconds) COMMAND_DURATION="${2:-}"; shift 2 ;;
    --verification) VERIFICATION="${2:-}"; shift 2 ;;
    --evidence-ref) EVIDENCE_REF="${2:-}"; shift 2 ;;
    --concurrent-with) CONCURRENT_WITH="${2:-}"; shift 2 ;;
    --waiting-seconds) WAITING_SECONDS="${2:-}"; shift 2 ;;
    --measurement-status) MEASUREMENT_STATUS="${2:-}"; shift 2 ;;
    --unavailable-reason) UNAVAILABLE_REASON="${2:-}"; shift 2 ;;
    --issue-class) ISSUE_CLASS="${2:-}"; shift 2 ;;
    --problem) PROBLEM="${2:-}"; shift 2 ;;
    --cause) CAUSE="${2:-}"; shift 2 ;;
    --correction) CORRECTION="${2:-}"; shift 2 ;;
    --repeated-proof) REPEATED_PROOF="${2:-}"; shift 2 ;;
    --responsible-role) RESPONSIBLE_ROLE="${2:-}"; shift 2 ;;
    --continuation) CONTINUATION="yes"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for required in SLICE PHASE STATUS OBSERVED_AT SUMMARY ASSESSMENT; do
  if [ -z "${!required// }" ]; then
    echo "ERROR: missing required value: ${required}" >&2
    usage >&2
    exit 2
  fi
done

case "$PHASE" in planning-inspection|implementation|review|verification|correction|waiting|handoff-bookkeeping) ;; *) echo "ERROR: invalid phase: $PHASE" >&2; exit 2 ;; esac
case "$STATUS" in started|completed|interrupted|failed) ;; *) echo "ERROR: invalid status: $STATUS" >&2; exit 2 ;; esac
case "$VERIFICATION" in executed|reused|deferred|not-applicable) ;; *) echo "ERROR: invalid verification state: $VERIFICATION" >&2; exit 2 ;; esac
case "$MEASUREMENT_STATUS" in measured|unavailable) ;; *) echo "ERROR: invalid measurement status: $MEASUREMENT_STATUS" >&2; exit 2 ;; esac
case "$ISSUE_CLASS" in none|new|known-repeat|hypothesis) ;; *) echo "ERROR: invalid issue class: $ISSUE_CLASS" >&2; exit 2 ;; esac

is_utc_timestamp() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; }
is_non_negative_seconds() { [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; }

for timestamp in "$OBSERVED_AT" "$INTERVAL_START" "$INTERVAL_END"; do
  if [ -n "$timestamp" ] && ! is_utc_timestamp "$timestamp"; then
    echo "ERROR: timestamps must be RFC3339 UTC values ending in Z" >&2
    exit 2
  fi
done

if [ -n "$INTERVAL_START" ] && [ -z "$INTERVAL_END" ] && [ "$STATUS" != "started" ]; then
  echo "ERROR: an interval start without an end is only valid for a started phase" >&2
  exit 2
fi
if [ -z "$INTERVAL_START" ] && [ -n "$INTERVAL_END" ]; then
  echo "ERROR: interval end requires interval start" >&2
  exit 2
fi
if [ -n "$INTERVAL_START" ] && [ -n "$INTERVAL_END" ] && [[ "$INTERVAL_END" < "$INTERVAL_START" ]]; then
  echo "ERROR: interval end precedes interval start" >&2
  exit 2
fi
if [ "$STATUS" = "completed" ] && [ -z "$INTERVAL_START" ] && [ "$MEASUREMENT_STATUS" != "unavailable" ]; then
  echo "ERROR: completed work needs an observed interval or an explicit unavailable measurement" >&2
  exit 2
fi
if [ "$MEASUREMENT_STATUS" = "unavailable" ] && [ -z "${UNAVAILABLE_REASON// }" ]; then
  echo "ERROR: unavailable measurements require --unavailable-reason" >&2
  exit 2
fi

for seconds in "$SESSION_ELAPSED" "$SLICE_ELAPSED" "$COMMAND_DURATION" "$WAITING_SECONDS"; do
  if [ -n "$seconds" ] && ! is_non_negative_seconds "$seconds"; then
    echo "ERROR: durations must be non-negative seconds, never polling waits" >&2
    exit 2
  fi
done
if [ -n "$COMMAND_DURATION" ] && [ -z "$COMMAND_ID" ]; then
  echo "ERROR: command duration requires --command-id" >&2
  exit 2
fi
if [ "$VERIFICATION" = "reused" ] && [ -n "$COMMAND_DURATION" ]; then
  echo "ERROR: reused verification cannot claim a new command duration" >&2
  exit 2
fi
if { [ "$VERIFICATION" = "reused" ] || [ "$VERIFICATION" = "deferred" ]; } && [ -z "${EVIDENCE_REF// }" ]; then
  echo "ERROR: reused or deferred verification requires --evidence-ref" >&2
  exit 2
fi
if { [ "$STATUS" = "failed" ] || [ "$STATUS" = "interrupted" ]; } && [ -z "${PROBLEM// }" ]; then
  echo "ERROR: failed or interrupted work requires --problem" >&2
  exit 2
fi
if [ "$PHASE" = "correction" ] && [ "$STATUS" = "completed" ] && { [ -z "${CORRECTION// }" ] || [ -z "${REPEATED_PROOF// }" ]; }; then
  echo "ERROR: completed correction requires --correction and --repeated-proof" >&2
  exit 2
fi

for value in "$SLICE" "$SUMMARY" "$ASSESSMENT" "$COMMAND_ID" "$EVIDENCE_REF" "$CONCURRENT_WITH" "$UNAVAILABLE_REASON" "$PROBLEM" "$CAUSE" "$CORRECTION" "$REPEATED_PROOF" "$RESPONSIBLE_ROLE"; do
  if printf '%s' "$value" | grep -Eqi '(authorization:|bearer[[:space:]]+|(^|[[:space:]])(token|secret|password|api[-_]?key)[[:space:]]*[:=])'; then
    echo "ERROR: do not record secrets, credentials, or sensitive command arguments" >&2
    exit 2
  fi
done

BRANCH="$(git branch --show-current)"
if ! SESSION_ID="$(chat_session_id_from_branch "$BRANCH")"; then
  echo "ERROR: current branch is not a chat branch: $BRANCH" >&2
  exit 1
fi
LOG_FILE="$(chat_log_file_for_session "$SESSION_ID")"
if [ ! -f "$LOG_FILE" ]; then
  echo "ERROR: missing chat log: $LOG_FILE" >&2
  exit 1
fi

insert_section_entry() {
  local section="$1" entry="$2" tmp entry_tmp
  tmp="$(mktemp)"; entry_tmp="$(mktemp)"
  printf '%s\n' "$entry" > "$entry_tmp"
  awk -v section="$section" -v entry_path="$entry_tmp" '
    BEGIN { in_section = 0; inserted = 0; found = 0; entry = ""; while ((getline line < entry_path) > 0) entry = entry (entry == "" ? "" : "\n") line; close(entry_path) }
    $0 == section { found = 1; in_section = 1; print; next }
    in_section && /^## / && inserted == 0 { print ""; print entry; print ""; inserted = 1; in_section = 0 }
    in_section && $0 == "- None recorded yet." { next }
    { print }
    END { if (found == 0) { print ""; print section; print ""; print entry } else if (in_section == 1 && inserted == 0) { print ""; print entry } }
  ' "$LOG_FILE" > "$tmp"
  mv "$tmp" "$LOG_FILE"; rm -f "$entry_tmp"
}

if ! grep -q '^## Activity Accounting$' "$LOG_FILE"; then
  insert_section_entry "## Activity Accounting" "- This legacy session began before standard activity accounting. New entries below are prospective; no historical timing is inferred."
fi

entry="### ${OBSERVED_AT} — ${PHASE}: ${SLICE}

Status: ${STATUS}
Parent-owned entry: yes
Continuation: ${CONTINUATION}
Summary: ${SUMMARY}
Assessment: ${ASSESSMENT}
Issue class: ${ISSUE_CLASS}
Verification: ${VERIFICATION}"
[ -n "$INTERVAL_START" ] && entry+="
Work-slice interval (UTC): ${INTERVAL_START}–${INTERVAL_END:-open}"
[ -n "$SESSION_ELAPSED" ] && entry+="
Session/calendar elapsed (observed): ${SESSION_ELAPSED}s"
[ -n "$SLICE_ELAPSED" ] && entry+="
Work-slice elapsed (observed): ${SLICE_ELAPSED}s"
[ -n "$COMMAND_ID" ] && entry+="
Command: ${COMMAND_ID}"
[ -n "$COMMAND_DURATION" ] && entry+="
Command execution duration (measured): ${COMMAND_DURATION}s"
[ -n "$EVIDENCE_REF" ] && entry+="
Evidence reference: ${EVIDENCE_REF}"
[ -n "$CONCURRENT_WITH" ] && entry+="
Concurrent work: ${CONCURRENT_WITH}
Wall-time rule: concurrent intervals are not added to session wall time."
[ -n "$WAITING_SECONDS" ] && entry+="
Waiting/paused time (observed): ${WAITING_SECONDS}s"
[ "$MEASUREMENT_STATUS" = "unavailable" ] && entry+="
Unavailable measurement: ${UNAVAILABLE_REASON}"
[ -n "$PROBLEM" ] && entry+="
Observed problem: ${PROBLEM}"
[ -n "$CAUSE" ] && entry+="
Cause: ${CAUSE}"
[ -n "$CORRECTION" ] && entry+="
Correction: ${CORRECTION}"
[ -n "$REPEATED_PROOF" ] && entry+="
Repeated proof: ${REPEATED_PROOF}"
[ -n "$RESPONSIBLE_ROLE" ] && entry+="
Responsible role: ${RESPONSIBLE_ROLE}"

insert_section_entry "## Activity Accounting" "$entry"
echo "Recorded activity accounting: ${PHASE} (${STATUS})"
