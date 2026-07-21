# Shell compatibility

Shell compatibility matters primarily in **persistent shell** mode. Direct jobs use an argument vector; interactive applications use their own command language; human-only panes transfer input responsibility to the user.

## Identify the active language

Do not select syntax from `$SHELL` alone. It usually names the login shell and can be stale after entering `adb shell`, SSH, a debugger, a REPL, or another nested shell.

Before injecting a completion acknowledgement:

1. Confirm that a shell, rather than an interactive application, owns the foreground.
2. Use backend process metadata and known launch history to identify the active shell.
3. Record the shell family and version when available.
4. Select only an adapter covered by current evidence.
5. If identity is ambiguous, send nothing and ask or use application-specific observation.

Probe an adapter in a disposable pane before using it with valuable state. A probe passing establishes syntax compatibility only; it does not establish full support.

## Current evidence

| Shell family | Evidence | Status |
|---|---|---|
| Bash | Live Zellij state-preservation smoke test | Prototype target |
| Dash | Local grammar and state probe | Not yet a support claim |
| Zsh | Local grammar and state probe | Not yet a support claim |
| mksh | Bourne-style candidate | Untested locally |
| Fish | Different grouping, status, variable, and export syntax | Unsupported until a dedicated adapter is tested |

## Bourne-style prototype envelope

The current Bash envelope also passes basic local probes under Dash and Zsh:

```sh
{ COMMAND; }; __relaytty_rc=$?; printf '\n__RELAYTTY_DONE_NONCE:%s\n' "$__relaytty_rc"
```

The brace group runs in the current shell so `cd` and exported variables can persist. This does not make arbitrary payloads portable: functions, aliases, arrays, startup options, quoting, traps, and error semantics still vary by shell.

Do not use the envelope after `exit`, `exec`, shell replacement, or an action whose delivery is uncertain. Generate a unique nonce for every action.

## Fish boundary

Do not translate the Bourne envelope into Fish ad hoc. Fish uses `begin`/`end`, `$status`, and `set`; grouping can also change variable scope. A Fish adapter must be tested for state preservation, failure status, cancellation, multiline commands, marker-like output, and startup configuration before use.

## Nested shells

Treat each foreground-language transition independently:

```text
login shell -> local persistent shell -> ssh or adb -> remote shell
```

A supported local Bash pane does not imply that an Android or remote shell accepts Bash syntax. After every transition, suspend the previous adapter and identify the new foreground language.
