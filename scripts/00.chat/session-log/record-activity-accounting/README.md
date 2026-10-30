<!-- agentic-artifact:
  schema: agentic-artifact/v2
  id: chat.script.session-log.record-activity-accounting.readme
  version: 1
  status: active
  layer: 00.chat
  domain: session-log
  disciplines:
  - agentic
  kind: capability-readme
  purpose: Explain bounded parent-owned activity accounting in session READMEs.
  portability:
    class: required
    targets:
    - llm-workbench
  used_by:
  - id: chat.script.session-log.record-activity-accounting
    path: scripts/00.chat/session-log/record-activity-accounting/script.sh
-->
# Record Activity Accounting

`script.sh` appends a concise, parent-owned work-slice entry to `## Activity
Accounting` in the current session README. It is a session-log helper, not a
general command runner or a verification receipt store.

Record an entry when a meaningful phase changes or a slice finishes—not after
every message or command. Small read-only tasks usually need only one completed
planning/inspection or handoff/bookkeeping entry. Use the same slice name on a
continuation; do not create a new session merely because a date or context
changed.

The supported phases are `planning-inspection`, `implementation`, `review`,
`verification`, `correction`, `waiting`, and `handoff-bookkeeping`. Every entry
has an observed UTC timestamp. Completed work provides its observed interval or
marks its measurement unavailable with a reason. The helper never derives
command time from polling or waits.

Verification entries identify whether proof was executed, reused, deferred, or
not applicable. Reused and deferred proof must name the trusted report or
receipt; a journal entry never becomes the receipt itself. Preserve stage
boundaries and deferred obligations. Do not rerun a check just to obtain a
duration.

For failures, interruptions, and corrections, record the observed problem,
supported cause (or mark it a hypothesis), correction, repeated proof, and
responsible role only when established. `known-repeat` distinguishes a repeated
mistake from a new issue. The final assessment names what worked, avoidable
effort supported by evidence, remaining uncertainty, and any recommendation.
Recommendations do not authorize follow-on work.

The parent consolidates activity accounting. A sub-agent supplies its relevant
intervals, command measurements, failures, corrections, reuse evidence, and
handoff through `record-sub-agent-activity`; the parent records overlap with
`--concurrent-with` and does not add overlapping child intervals to wall time.

Keep entries safe: use command identifiers and report paths, not raw command
output, environment values, credentials, or sensitive arguments. The helper
rejects common credential-shaped values, but this is a guardrail, not a reason
to paste sensitive material.

Structural validation checks allowed phases/states, UTC timestamps, timing
dependencies, correction proof, reuse evidence, and selected sensitive text.
It cannot prove that prose is complete, that a cause is true, that intervals do
not overlap outside the supplied declaration, or that a report is trusted; those
remain parent judgment under the existing lifecycle controls.
