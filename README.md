# llm-workbench

LLM Workbench turns AI coding conversations into isolated, reproducible Git workspaces.

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

This installs into your target repo:

- `npm run chat:*` commands in `package.json`
- helper scripts and automation
- AGENTS.md configured for your coding assistant
- `.llm-workbench/install-manifest.tsv` for safe uninstall
- session logs under `commitLogs/` when chats run

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

### Coming Soon

Install using:

```bash
npx llm-workbench init
llm-workbench start "refactor auth flow"
```