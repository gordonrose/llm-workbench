# llm-workbench

A developer tool that makes AI coding sessions reproducible, isolated and mergeable. mo

Run AI coding sessions in isolated git worktrees without dirtying `main`.

## Why use it?

AI coding tools are useful, but they make it easy to lose context, mix unrelated changes, or pollute your main branch.

`llm-workbench` gives every chat session its own branch, worktree, and session log so you can experiment safely and merge only when ready.

## Quick start

## Quick start

```bash
git clone https://github.com/gordonrose/llm-workbench.git
cd llm-workbench

bash scripts/install.sh --dry-run /path/to/your/repo
bash scripts/install.sh --apply /path/to/your/repo
```
Then in your repo:
```
npm run chat:list
npm run chat:new -- "your prompt here"
```


### Coming Soon
```bash
npx llm-workbench init
llm-workbench start "refactor auth flow"
```

This creates:

* a new git branch for the chat
* a dedicated worktree for the implementation
* a session log under commitLogs/
* helper commands for checkpointing and merge readiness


## Who is this for?

Developers using Claude Code, Codex, Cursor or Copilot coding assistants who want safer multi-session repo workflows.

## What it does not do

* does not push to remote
* does not rewrite history
* does not delete branches without approval
* does not require a specific LLM provider