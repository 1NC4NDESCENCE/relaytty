# RelayTTY

> A terminal your agent can keep—and you can take over.

RelayTTY is an experimental Codex skill for work that does not fit a sequence of disposable shell commands: an `adb shell` whose state must survive, a debugger or REPL waiting for input, a build you want to watch, or a terminal interface that must occasionally belong to a human.

It defines a **relay terminal**: a persistent terminal session with explicit identity, observation, ownership, and recovery rules. The agent can operate it, the user can attach to the same live state, and control can pass between them without pretending that a terminal is stateless.

The project is at the **prototype stage**. The initial target is Linux with Zellij 0.44 or newer. Support for tmux, macOS, native Windows, and polished installation comes after the behavioral contract is proven.

## The problem

Ordinary command tools are excellent when a command starts, returns output, and exits. They become awkward when the real object of work is a continuing terminal state:

- `cd`, `export`, shell functions, and nested shells must persist;
- a debugger, REPL, SSH session, or TUI owns the foreground;
- a process requires a controlling terminal;
- output continues while the agent is doing something else;
- the user needs to watch, type, authenticate, or inspect directly;
- an agent turn ends, but the process must not.

Backgrounding a process solves only lifetime. It does not provide a safe answer to identity, input routing, observation, human takeover, or recovery after uncertainty.

RelayTTY does not implement a PTY, terminal emulator, or multiplexer. It supplies the decision rules and operating discipline that let an agent use an existing multiplexer reliably.

## The experience

1. The agent decides whether the task actually needs a relay terminal.
2. It creates or discovers a named session and records stable pane identities.
3. It chooses one mode: direct job, persistent shell, interactive application, or human-only.
4. It sends input to an explicit pane and observes completion without depending on visual focus.
5. When the user takes over, the agent stops reading and writing that pane.
6. On return, the agent re-discovers state before continuing.

```text
 human terminal ───────┐
                       v
 agent policy ──> relay contract ──> Zellij session ──> shell / adb / debugger / TUI
      ^                     |
      └──── metadata, events, bounded screen snapshots
```

The important product is the contract in the middle. Zellij is the first backend, not the definition of RelayTTY.

## Prototype slice

The first end-to-end prototype is intentionally narrow:

- Linux and Bash;
- Zellij 0.44 or newer;
- a persistent shell whose `cwd` and exported values survive commands;
- an Android-style nested shell recipe;
- a long-running visible job;
- a dedicated pane handed to a human, then safely resumed;
- a negative case proving that a one-shot command does not create a session.

This slice tests the hard semantics before adding platforms and backends. WSL may be useful as a Linux test environment, but it is not yet a promise of Windows support.

## Support policy

| Environment | Status | Meaning |
|---|---|---|
| Linux + Zellij 0.44+ | Prototype target | Developed and evaluated here first |
| WSL2 + Zellij | Experimental | Useful evidence, not native Windows support |
| macOS + Zellij | Planned validation | No support claim until tested in CI and by humans |
| Linux/macOS + tmux | Planned backend | Contract first, adapter second |
| Native Windows | Deferred | Requires a deliberate backend and terminal model |

Support is an evidence claim, not a syntax claim. A backend is supported only when installation, lifecycle, identity, input, observation, handoff, recovery, and cleanup are exercised repeatably.

## Safety rules

- Every mutation targets a discovered session and pane ID; focus is never an address.
- Exactly one actor may write to a pane at a time.
- Human ownership disables agent input and capture for that pane.
- Sensitive interaction belongs in a dedicated human-owned pane.
- Uncertain actions are inspected, not automatically repeated.
- Timeouts do not imply failure and never justify destructive recovery by themselves.
- Cleanup touches only resources RelayTTY created and can still identify.

A terminal multiplexer is not a security boundary. RelayTTY reduces accidental interference and disclosure; it does not isolate mutually hostile actors.

## What persists

RelayTTY distinguishes several different kinds of persistence:

- **process persistence**: the process survives an agent turn or client disconnect;
- **terminal persistence**: the PTY and foreground application remain alive;
- **shell persistence**: `cwd`, exported variables, functions, and nested shells remain;
- **identity persistence**: the next actor can find the same session and pane;
- **ownership persistence**: everyone knows whether the human or agent may act.

Claiming merely that “the session persists” hides the failures that matter.

## Installation

RelayTTY is not published yet. During development, use the skill at [`skill/relaytty`](skill/relaytty).

Install the development version directly from GitHub:

```sh
npx skills add 1NC4NDESCENCE/relaytty --skill relaytty
```

Updates should remain ordinary repository updates followed by the installer’s update path. User-facing behavior changes will be documented at the repository root; the installable skill will stay small and self-contained.

## Contributing

Real inconveniences are design input. If RelayTTY chooses the wrong mode, targets the wrong pane, loses state, interferes with human control, captures something sensitive, or recovers badly, please open a focused report using the guidance in [`CONTRIBUTING.md`](CONTRIBUTING.md).

Each reproducible failure should become an evaluation or compatibility test. That gives users—including the original reporter—a direct path from “this was annoying” to a durable fix.

The reasoning behind the test system and the publication gates are in [`TESTING.md`](TESTING.md). The current backend smoke test is [`tests/smoke_zellij.sh`](tests/smoke_zellij.sh).

## License

RelayTTY is available under the [MIT License](LICENSE).

## Roadmap

1. Prove the Zellij/Linux prototype and its failure behavior.
2. Build repeatable scenario evaluations and fault-injection tests.
3. Validate macOS separately and decide whether Zellij is sufficient there.
4. Add a tmux adapter only if it can preserve the same contract.
5. Publish the skill, a short demonstration, and a technical essay at [1ncandescence.me](https://1ncandescence.me/) explaining the broader terminal-state problem and the testing philosophy.

The README should eventually include a short, captioned terminal recording. It should demonstrate one idea—agent work, human takeover, agent resumption—in under a minute. The written contract remains canonical because recordings age quickly and are not searchable or accessible to everyone.
