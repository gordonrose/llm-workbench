# Adapting To Your Repo

The workbench is intentionally small at the root and detailed in the harness
folders.

## Keep AGENTS.md Small

Use `AGENTS.md` as a router. Put detailed rules in workflows, standards,
checklists, and scripts.

`llm-workbench` patches instruction files with a managed block instead of
owning the whole file when the target repo already has local instructions. Keep
repo-specific rules outside:

```txt
<!-- llm-workbench:start -->
...
<!-- llm-workbench:end -->
```

Updates may replace that block, but should leave the rest of the file alone.

## Understand Managed Ownership

Install and adopt write `.llm-workbench/manifest.json`. That file is the update
receipt.

Workbench-owned files can be replaced by `llm-wb update` when their current
checksum still matches the manifest. Repo-owned files are not replaced.
Instruction files can have a managed block, which lets the workbench update only
that block.

Put target-repo behavior in local files and local layers. Do not edit managed
workbench files directly unless you want the next update to stop with a
conflict. If the change is reusable, make it upstream in `llm-workbench`; if it
is repo-specific, keep it outside the managed workbench surface.

## Add A Layer Deliberately

If your repo needs product, infrastructure, docs, or education governance, add
a layer under `.agentic/` and update `AGENTS.md` only with the routing summary.

## Prefer Scripts For Repeatable Checks

If a process can be checked deterministically, add or update a governed script
instead of relying only on prose.

## Keep Session History Local To The Repo

Do not import another repo's `commitLogs/`. The first chat in your repo creates
your repo's own session history inside the chat-owned worktree.

`commitLogs/`, `.git/`, local branches, local worktrees, product code, and
repo-specific `.agentic` layers are not workbench update targets unless you
explicitly add them to your own process.

## Promote Reusable Lessons Upstream

When a target repo teaches you something reusable about the workbench, promote
that lesson back to `llm-workbench` instead of letting each repo drift.
