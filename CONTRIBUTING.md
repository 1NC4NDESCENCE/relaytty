# Contributing to RelayTTY

RelayTTY should improve through real terminal failures, not guesses about every possible environment. Small, reproducible reports are especially valuable.

## Reporting a problem

Describe:

- the intended outcome;
- operating system and version;
- multiplexer and version;
- shell and relevant application, such as ADB, LLDB, SSH, or a REPL;
- the RelayTTY mode you expected, if known;
- the last action whose outcome is certain;
- what happened during any human handoff;
- whether the failure reproduces without private data.

Do not paste tokens, passwords, private terminal contents, complete environment dumps, or shell history. Replace sensitive values with structural placeholders. If safe reproduction is impossible, see [`SECURITY.md`](SECURITY.md).

## Turning a report into a fix

1. Reduce the failure to the smallest scenario.
2. Classify it as selection, lifecycle, addressing, coordination, observation, recovery, or documentation.
3. Add a failing regression evaluation where practical.
4. Fix the narrowest layer that owns the behavior.
5. Run the full scenario suite, including non-activation cases.
6. Update compatibility claims only when the evidence changed.

| Failure | Likely home |
|---|---|
| Skill activates for a simple command | `SKILL.md` description or selection rules |
| Pane command differs by version | Backend reference and compatibility tests |
| ADB device and terminal identity are confused | ADB recipe |
| Agent acts during user control | Core ownership policy and regression evaluation |
| README setup is unclear | Human-facing documentation |

## Compatibility claims

“The command exists” is not enough. A supported combination must cover installation, session creation and discovery, stable pane addressing, input, observation, detach/reattach, human handoff, ambiguous recovery, and scoped cleanup.

When adding a platform or backend, record exact versions and distinguish automated coverage from manual exploratory evidence.

## Change hygiene

- Keep the installable skill concise and move detailed recipes into its `references/` directory.
- Use current official documentation and installed `--help` output as primary sources for backend behavior.
- Avoid diagnostics that collect terminal contents or environment values by default.
- Do not broaden the product into a terminal multiplexer or general orchestration framework without new evidence and an explicit design decision.
