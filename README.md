# llm-workbench

Turns AI coding conversations into isolated, reproducible Git workspaces.

Run AI coding sessions in isolated git worktrees without dirtying `main`.

## Why use it?

AI coding tools are useful, but they make it easy to lose context, mix unrelated changes, or pollute your main branch.

`llm-workbench` gives every chat session its own branch, worktree, and session log so you can experiment safely and merge only when ready.

### Before LLM-Workbench
* one long AI conversation trying to solve multiple problems
* random commits
* forgot why code changed
* dirty main
* abandoned branches

### After LLM-Workbench

```text
Main
    │.                         │
    ▼.                         ▼
Start chat #1.            Start chat #n
    │.                         │
    ▼.                         ▼
Create worktree/branch.       ...
    │
    ▼
Code with AI
    │
    ▼
Checkpoint
    │
    ▼
Continue tomorrow
    │
    ▼
Merge back to main
```

* one branch per AI session
* session logs
* isolated worktrees
* merge when ready

## Quick start

Public npm install is the intended user path:

```bash
cd /path/to/your/repo

npx llm-wb init --dry-run
npx llm-wb init
```

Then start and inspect work from that repo:

```bash
npx llm-wb new "your prompt here"
npx llm-wb sessions list
npx llm-wb commit -m "Describe the completed work"
npx llm-wb merge-main
```

`llm-wb list` lists installed workbench commands. To list active chat sessions,
use `llm-wb sessions list`.

This installs into your target repo:

* Adds the `llm-wb` CLI
* Configures AGENTS.md
* Installs workbench scripts
* Enables safe uninstall
* Creates session logs that preserve decisions, prompts and commit history.

Each new llm-chat session then creates:

- a chat-owned branch
- a git worktree for that branch
- a session log/checkpoint record
- merge-readiness checks before promotion back to `main`

Works with existing repositories. No migration required. Uninstall removes only files owned by LLM Workbench.

## Who is this for?

Developers using Claude Code, Codex, Cursor or Copilot coding assistants who want safer multi-session repo workflows.

## Security Boundaries

* does not push to remote
* does not rewrite history
* does not delete branches without approval
* does not require a specific LLM provider
