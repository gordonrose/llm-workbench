# Workflows

## Start A Chat

Chat startup is governed by:

```txt
.agentic/00.chat/workflows/chat-start.md
```

At startup the harness finds or creates session metadata, records the chat
lifecycle workflow, and verifies the chat-owned worktree when writes are
allowed. It does not assign the whole chat a durable layer, mode, or workflow.

For assistants that can consume structured startup output:

```bash
llm-wb new --json "Describe the prompt"
```

The JSON packet includes the session log, chat-owned worktree, lifecycle
workflow, latest context-packet references, and first prompt.

Use `npx llm-wb ...` instead of `llm-wb ...` when the CLI is not installed
globally or linked into your shell.

## Commit Work

Commit preparation is governed by:

```txt
.agentic/00.chat/workflows/chat-commit.md
```

The before-commit gates check prerequisites, session log safety, deterministic
process drift, metadata headers, and governed command drift.
Before task commits, the session log must include context hygiene: a compact
summary of what should survive from noisy file reads, command output, diffs,
logs, errors, and tool calls.

The public CLI shortcut is:

```bash
llm-wb commit -m "Describe the completed work"
```

This wraps the existing commit gates, creates the task commit, records it in the
session log, and checkpoints session evidence.
If you continue the same chat into another implementation phase after that
checkpoint, run `/compact` so Codex keeps the commit summary, decisions,
unresolved issues, and context hygiene instead of raw intermediate output.

Transcript metrics are provider-neutral. Codex can use the bundled transcript
adapter; other assistants can provide values with `CHAT_TRANSCRIPT_PROVIDER`,
`CHAT_TRANSCRIPT_PATH`, `CHAT_TRANSCRIPT_BYTES`, and `CHAT_TRANSCRIPT_SOURCE`.
Portable mode records unavailable metrics without blocking. Strict mode is
available through `CHAT_TRANSCRIPT_METRICS_MODE=strict`.

Cost metrics are provider-neutral by default. Bundled pricing records cost as
unavailable until `CHAT_COST_PROFILE` or `CHAT_COST_PRICING_FILE` selects a
concrete pricing profile.

## Refresh From Main

Main refresh is governed by:

```txt
.agentic/00.chat/workflows/chat-refresh-from-main.md
```

The workflow separates read-only status, rehearsal, and apply.

For active chat/session visibility today:

```bash
llm-wb sessions list
```

## Promote To Main

Promotion is governed by:

```txt
.agentic/00.chat/workflows/chat-promote-to-main.md
```

The harness treats local merge readiness separately from remote push. A push
always needs separate explicit approval.

The current CLI shortcut verifies readiness and performs only the local merge:

```bash
llm-wb merge-main
```

## Report Or Close A Chat

Reporting and closeout are governed by:

```txt
.agentic/00.chat/workflows/chat-reporting.md
.agentic/00.chat/workflows/chat-cleanup.md
```

These workflows help summarize work, inspect active workspaces, and clean up
empty chat branches when it is safe.

`llm-wb list` intentionally lists installed workbench commands. Use
`llm-wb sessions list` to list active chat sessions.

## Export Work For Review

To send the active chat worktree to another model, engineer, or verification
environment:

```bash
npm run chat -- download repo
```

To send only files changed relative to local `main`:

```bash
npm run chat -- download repo diff
```

Both commands create a zip review bundle outside the repo by default and include
`llm-workbench-export-manifest.json` with branch, base ref, included files,
deleted files, and untracked files.
