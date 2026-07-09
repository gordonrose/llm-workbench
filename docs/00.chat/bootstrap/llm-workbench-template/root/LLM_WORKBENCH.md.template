# LLM Workbench Instructions

This generic adapter is for CLI agents and assistants without a native
repository-instruction filename, including Mistral-backed tools.

At the start of each chat, follow `.agentic/00.chat/workflows/chat-start.md`.
`ignore chat start` skips governed startup.

Use the current branch's `commitLogs/<session>/README.md` as the first source
of truth for chat lifecycle, branch, worktree, context-packet references,
commits, and metrics.

<!-- deterministic-check: allow reason="prompt routing may be manual or repo-specific; no universal script can decide whether a context router exists" -->
Do not assign the whole chat a durable layer, mode, or workflow. Use
prompt-level routing only when a prompt needs layer, mode, workflow, corpus, or
rule context; then use the current user request, this repo's assistant
instructions, and any available repo-provided context router.

Governed chat-start may create or verify the chat branch, chat-owned worktree,
and session log from the opening prompt before task write permission is
granted. After bootstrap, task files remain read-only until the user explicitly
grants write permission.
