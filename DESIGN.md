# RelayTTY design

## Definition

A **relay terminal** is a persistent terminal session whose identity, observation method, active owner, and recovery behavior are explicit enough for control to pass safely between an agent and a human.

RelayTTY is the behavioral layer around that object. The initial implementation is a Codex skill backed by Zellij. This separation matters: if the project succeeds, the contract should survive a different multiplexer or agent host.

## System-level model

RelayTTY has five concerns:

1. **Selection** — decide whether persistent terminal semantics are needed.
2. **Lifecycle** — create, discover, retain, and clean up sessions and panes.
3. **Addressing** — route every action through stable, typed backend identities. A numeric ID alone is insufficient when backend namespaces overlap.
4. **Coordination** — make ownership and sensitive handoff explicit.
5. **Evidence** — observe state and completion without assuming that captured text is a perfect event log.

Backend commands are mechanisms beneath these concerns. Application recipes such as ADB or LLDB are specializations above them.

## Prototype hypothesis

The cheapest useful artifact is a skill, not a new daemon. Existing multiplexers already provide PTYs, lifetime, attachment, and pane addressing. The open question is whether careful policy plus a small set of tested recipes can make those primitives reliable enough for agent work.

Build a separate executable only when tests expose a repeated need that cannot be expressed safely through the backend CLI—for example atomic ownership, durable structured state, or lossless event acknowledgement.

## Session modes

| Mode | Use when | Completion model |
|---|---|---|
| Direct job | One long-running command needs a visible TTY but no continuing shell | Process/pane lifecycle |
| Persistent shell | Shell mutations such as `cd` and `export` must survive | Unique command acknowledgement |
| Interactive application | A debugger, REPL, SSH client, or TUI owns the foreground | Application-specific prompt, event, or user decision |
| Human-only | The user must type or inspect, especially around secrets | Explicit hand-back |

Choosing the wrong mode is a semantic error. A prompt marker suitable for a shell must not be injected into a debugger, and a human-owned pane must not be polled for contents.

## State dimensions

These dimensions are independent and must be tested independently:

- process alive;
- PTY alive;
- session discoverable;
- pane identity stable;
- shell state preserved;
- foreground application known;
- current owner known;
- observation freshness known;
- last action outcome known.

This is the missing big picture behind many terminal bugs: “alive” does not imply “addressable,” “addressable” does not imply “safe to write,” and visible output does not prove that an action ran exactly once.

## Safety invariants

1. **Explicit addressing:** focus and layout are presentation state, never routing state. Preserve identity type or namespace as well as its numeric value.
2. **Single writer:** at most one agent or human may provide input at a time.
3. **No observation during sensitive ownership:** human-only means neither automated input nor content capture.
4. **Inspect before replay:** after timeout, disconnect, or ambiguous output, determine state before retrying a non-idempotent action.
5. **Scoped cleanup:** terminate only positively identified resources created for the current task.
6. **Bounded claims:** a timeout means the observer stopped waiting, not that the process failed.
7. **Re-discovery after handoff:** pane IDs, foreground program, and ownership are rechecked when the agent resumes.

## Observation hierarchy

Prefer the strongest available evidence:

1. structured backend metadata and lifecycle events;
2. an application-native status or protocol;
3. a unique acknowledgement emitted by a controlled shell;
4. bounded screen snapshots as a visual fallback;
5. user confirmation when automation cannot establish the fact safely.

Screen text is a rendered view, not an authoritative transcript. It can be truncated, redrawn, duplicated, hidden, or confused with user output.

## Persistence boundary

The prototype persists only what Zellij and the live processes persist. RelayTTY does not initially promise recovery after machine reboot, backend server loss, or process death. It does promise that an agent turn ending or a client detaching will not by itself discard the terminal.

Metadata needed for reliable resumption should be reconstructible from the backend whenever possible. If later tests show that ownership or action acknowledgements need durable external state, that is evidence for a small state component—not permission to invent one pre-emptively.

## Prototype slice

The first prototype must demonstrate:

- activation for an actually stateful shell task;
- non-activation for an ordinary one-shot command;
- preservation of `cwd` and an exported value across commands;
- explicit routing to a pane that is not visually focused;
- observation of a visible long-running job;
- a nested Android-style shell with device identity kept separate from terminal identity;
- human handoff with no automated capture or input during ownership;
- re-discovery and safe continuation after hand-back;
- timeout and ambiguous-action behavior that does not blindly replay or destroy state.

## Success criteria

The prototype succeeds when the scenarios above pass repeatedly, failures leave diagnosable metadata without leaking content, and a new contributor can reproduce the results from written instructions. A pleasing demo is useful evidence of comprehension, but it is not evidence of recovery behavior.

## Deferred decisions

- macOS support and its backend-specific edge cases;
- native Windows versus WSL positioning;
- a tmux adapter;
- application-specific adapters beyond the first ADB recipe;
- cross-reboot persistence;
- multiple agents sharing one relay terminal;
- a daemon, protocol, or structured state store;
- publication channel and final repository owner.

Each should be pulled forward by a concrete scenario or failure, not by the desire to look comprehensive.
