# Human handoff procedure

Ownership is a state transition, not a polite message. A pane is either agent-owned or human-owned; ambiguous ownership means nobody writes until it is resolved.

## Before handoff

1. Prefer a dedicated pane, especially for passwords, tokens, private files, or a terminal editor. Zellij's `action edit` can create this pane and returns its typed identity.
2. Finish or stop any automated observer that reads pane contents.
3. Record the session name, pane ID, foreground application if known, and the last certain action.
4. Tell the user how to attach and what event constitutes hand-back.
5. Mark the pane human-owned before inviting input.

For a one-shot interactive command, use `scripts/human-command.sh` with Zellij's `--close-on-exit`. This gives the user time to read an explicit success or failure result; their final Enter closes the tab instead of rerunning the command.

## During human ownership

- Send no characters, keys, resize actions, focus changes, or application commands.
- Do not dump, stream, summarize, or log pane contents.
- Metadata-only liveness checks are acceptable only when necessary and when they cannot disturb the pane.
- Do not infer hand-back from silence, a prompt, elapsed time, detach, or process output.

## On hand-back

1. Require an explicit user signal outside the shared terminal.
2. Re-query session and pane metadata.
3. Determine whether the pane still exists and which application owns the foreground.
4. Ask if sensitive material remains visible when content capture would be needed.
5. Resume only after ownership and application state are unambiguous.

## Limits

This protocol prevents accidental interference; it is not secret isolation from the multiplexer, host, logs, or a malicious actor. Use a stronger operating-system boundary when that threat model matters.

If unexpected human input is detected while the agent believes it owns the pane, stop sending input, preserve the terminal, and ask who owns it. Do not try to “finish quickly” or undo unknown actions.

## Browser device flows

A CLI can authenticate successfully even when its attempt to open the browser fails. Before starting, check for a usable opener such as `xdg-open`, `wslview`, or a verified platform bridge. If none is available, tell the user to open the displayed URL manually. Treat opener failure as a presentation failure, not proof that authentication failed; use the CLI's final exit status and a separate metadata-only authentication check after hand-back.
