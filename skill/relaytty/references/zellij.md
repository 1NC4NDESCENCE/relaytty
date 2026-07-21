# Zellij backend procedure

This prototype targets Zellij 0.44 or newer on Linux. Inspect `zellij --version` and the relevant `--help` output because CLI details can change.

## Create and discover

First determine whether the agent already runs inside Zellij:

```sh
printf '%s\n' "${ZELLIJ_SESSION_NAME-}"
```

If this names a session, prefer creating a pane or tab there. Do not tell the user to attach to another session from the existing Zellij client: that creates a nested client, complicates keybindings and ownership, and usually provides worse visibility. Create a separate session only when isolation is an explicit requirement or the agent is outside Zellij.

Create a detached session:

```sh
zellij attach --create-background SESSION_NAME
```

List names without decorative output:

```sh
zellij list-sessions --short --no-formatting
```

Query all pane metadata as JSON:

```sh
zellij --session SESSION_NAME action list-panes --json --all
```

Session creation can become visible before its first terminal pane appears. Poll structured metadata with a short, bounded deadline; do not interpret the first empty result as a permanent failure.

Parse the JSON and first select entries where `is_plugin` is `false`. Zellij's plugin-pane and terminal-pane ID spaces can overlap: a plugin and a terminal may both report numeric ID `0`. Retain the session name, terminal-pane ID, and the fact that it is not a plugin. Treat titles as human labels, not routing addresses. Never route through whichever pane is focused.

`new-pane` prints the created pane ID and accepts a command after `--`:

```sh
zellij --session SESSION_NAME action new-pane --name LABEL --cwd WORKDIR -- COMMAND ARGUMENT
```

## Send input

Target the retained **terminal** pane explicitly. `paste` sends text and `send-keys` sends named keys:

```sh
zellij --session SESSION_NAME action paste --pane-id PANE_ID -- 'TEXT'
zellij --session SESSION_NAME action send-keys --pane-id PANE_ID ENTER
```

Do not concatenate untrusted text into shell syntax. Prefer a direct job with an argument vector when persistence of shell state is unnecessary.

## Persistent-shell acknowledgement

For a controlled shell command, append a unique, unpredictable nonce and exit status:

```sh
{ COMMAND; }; __relaytty_rc=$?; printf '\n__RELAYTTY_DONE_NONCE:%s\n' "$__relaytty_rc"
```

The brace group runs in the current shell, so successful `cd`, `export`, aliases, and functions can persist. Generate a new nonce for every action. Wait for exactly that acknowledgement; old screen text is not completion evidence.

Do not use this wrapper when:

- an interactive application currently owns the foreground;
- the command intentionally replaces or exits the shell;
- command text or output is sensitive;
- the action might already have run and its outcome is uncertain.

## Observe

Use the least invasive evidence that answers the question:

1. `action list-panes --json --all` for identity and lifecycle metadata;
2. `action subscribe --pane-id PANE_ID --format json` for supported events;
3. `action dump-screen --pane-id PANE_ID --full` for a bounded visual snapshot.

Screen dumps are rendered terminal state. Redraws, scrollback limits, wrapping, and application UI behavior make them unsuitable as a lossless log. Never dump a human-owned or sensitive pane.

## Direct jobs

Create a dedicated pane with the command directly after `--`. Completion is the command or pane lifecycle, not a shell prompt. Keep its pane ID separate from any control shell.

## Human attachment

Tell the user the session name and let them attach with:

```sh
zellij attach SESSION_NAME
```

Follow the ownership procedure in [human-handoff.md](human-handoff.md) before they type.

When already inside the user's Zellij session, create a named tab instead of asking them to attach:

```sh
zellij action new-tab --name LABEL --close-on-exit -- \
  /path/to/relaytty/scripts/human-command.sh COMMAND ARGUMENT
```

The helper prints a result and waits for Enter. `--close-on-exit` then closes the tab after that acknowledgement. Without this combination, Zellij may hold the exited pane and make Enter rerun the command—dangerous for `sudo`, package installation, and other non-idempotent actions.

For a file that the user should edit in the terminal, Zellij can open the configured editor and report a typed pane ID such as `terminal_4`:

```sh
zellij --session SESSION_NAME action edit --cwd WORKDIR FILE
```

Parse the returned type and number, confirm the new non-plugin pane through `list-panes`, and mark it human-owned before the user begins. Do not capture that pane merely to detect whether the editor exited; use metadata and explicit hand-back.

## Cleanup

Prefer closing the exact RelayTTY-created pane over killing a session that may contain user work. Before cleanup, re-query metadata and verify the recorded identity. If identity is ambiguous, leave the resource intact and report it.
