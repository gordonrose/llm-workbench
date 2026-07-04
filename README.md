# llm-workbench

Run AI coding sessions in isolated git worktrees without dirtying `main`.

## Why use it?

AI coding tools are useful, but they make it easy to lose context, mix unrelated changes, or pollute your main branch.

`llm-workbench` gives every chat session its own branch, worktree, and session log so you can experiment safely and merge only when ready.

## Quick start

```bash
npx llm-workbench init
llm-workbench start "refactor auth flow"

This creates:

* a new git branch for the chat
* a dedicated worktree for the implementation
* a session log under commitLogs/
* helper commands for checkpointing and merge readiness

Common commands

llm-workbench sessions
llm-workbench start "add user settings page"
llm-workbench checkpoint
llm-workbench status
llm-workbench merge-ready

## Who is this for?

Developers using Claude Code, Codex, Cursor or Copilot coding assistants who want safer multi-session repo workflows.

What it does not do

* does not push to remote
* does not rewrite history
* does not delete branches without approval
* does not require a specific LLM provider

## Learn More

- `docs/concepts.md`
- `docs/install.md`
- `docs/workflows.md`
- `docs/adapting-to-your-repo.md`
- `docs/public-beta-contract.md`
