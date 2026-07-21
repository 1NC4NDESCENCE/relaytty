---
name: relaytty
description: Create and manage persistent, human-observable terminal sessions for interactive programs, stateful shells, long-running builds, debuggers, REPLs, adb shell, SSH, terminal UIs, and human takeover. Use when work needs continued stdin, preserved cwd/environment/application state across turns, a controlling terminal, detach/reattach, live terminal output, or a pane the user can observe or control. Do not use for ordinary one-shot commands or merely to hide work in the background. The current prototype supports Zellij 0.44 or newer on Linux.
---

# RelayTTY

Treat a persistent terminal as shared state, not as a long shell command. Use Zellij to preserve the PTY and processes; use this workflow to preserve identity, ownership, and certainty.

## Keep these invariants

- Discover and record session and pane IDs. Never use visual focus as an address.
- Permit one writer at a time.
- During human ownership, send no input, capture no content, and change no focus.
- Put sensitive interaction in a dedicated pane.
- After a timeout or disconnect, inspect before retrying. Never assume failure and blindly replay.
- Clean up only resources created and positively identified for this task.

## Decide whether to use RelayTTY

Use it when at least one of these is essential:

- shell or application state must survive later commands or agent turns;
- the foreground program needs continuing input or a controlling terminal;
- the user needs to attach, observe, or take control of the same live terminal;
- output continues over time and a later decision depends on it.

Do not use it for a normal command that can run to completion through the ordinary command tool. Persistence has coordination and cleanup costs; “run this in the background” alone is not sufficient.

## Choose one mode

1. **Direct job** — create a pane that runs one long-lived command. Observe process and pane lifecycle.
2. **Persistent shell** — keep a shell and send commands to it. Use unique acknowledgements to determine completion while preserving `cd` and `export`.
3. **Interactive application** — start a debugger, REPL, SSH client, nested shell, or TUI. Use application-specific state; do not inject shell markers into its input.
4. **Human-only** — hand a dedicated pane to the user. Suspend all automated input and content capture until explicit hand-back.

If the mode is unclear, inspect the foreground program and ask before sending input that could be interpreted in more than one way.

## Operate the relay

1. Inspect installed Zellij version and command help. Require 0.44 or newer for this prototype.
2. Check `ZELLIJ_SESSION_NAME` before creating or attaching. When already inside Zellij, use a new pane or tab in that session; do not nest another attachment by default.
3. Otherwise choose a collision-resistant session name, create or discover it, then query structured pane metadata.
4. Record the session name and a terminal pane ID after filtering out plugin panes, plus the chosen mode and current owner. A Zellij plugin pane and terminal pane can share a numeric ID.
5. Send input only to the recorded pane ID.
6. Observe through backend metadata or application-native state first. Use bounded screen snapshots only as a fallback.
7. On human hand-back, re-query pane metadata and foreground state before acting.
8. On completion, preserve the session if continued use was requested; otherwise clean up only the owned pane or session.

## Read the relevant procedure

- For Zellij commands, explicit addressing, acknowledgements, observation, and cleanup, read [references/zellij.md](references/zellij.md).
- For Android devices and nested `adb shell` state, also read [references/adb.md](references/adb.md).
- Before any user takeover, sensitive input, or terminal editor, read [references/human-handoff.md](references/human-handoff.md).

For a one-shot command that needs human interaction, run it through `scripts/human-command.sh` in a pane or tab created with `--close-on-exit`. The helper preserves the command's exit status, shows an explicit colored result, and waits for Enter before Zellij closes it.

Installed command help is authoritative for the local version. If a required operation is unavailable, stop before mutation, preserve existing state, and report the exact unsupported step.
