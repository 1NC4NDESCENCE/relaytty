# RelayTTY contributor instructions

Read `README.md` and `DESIGN.md` before making substantial changes.

## Product boundaries

- Build behavioral guidance and evidence around an existing terminal multiplexer.
- Do not grow RelayTTY into a PTY server, terminal emulator, multiplexer, or general agent orchestrator.
- Keep human-facing project documentation outside the installable skill.
- Keep `SKILL.md` concise; put backend- and application-specific procedures in linked references.

## Safety invariants

- Address panes by stable IDs discovered from the backend; never rely on focus.
- Allow only one writer at a time.
- While a human owns a pane, do not send input, capture contents, or change focus.
- Do not capture panes used for sensitive input.
- If it is uncertain whether an action ran, inspect state; do not replay it blindly.
- Clean up only resources RelayTTY created and positively identified.
- A timeout means inspect and report, not kill and recreate.

## Development workflow

- Check current official documentation and installed `--help` output before changing backend behavior, compatibility claims, or distribution instructions.
- Make support claims only for combinations covered by repeatable tests.
- Fix a problem at the narrowest appropriate layer: core policy, backend adapter, application recipe, documentation, or test.
- Turn every reported bug into a regression evaluation when practical.
- Test both activation and non-activation; unnecessary terminal sessions are product failures too.
- Diagnostics must not include terminal contents, environment values, command history, or input by default.

## Prototype scope

- Linux with Zellij 0.44 or newer.
- Prove a persistent shell, an Android-style nested shell, human handoff, resumption, and non-activation.
- Defer tmux, LLDB-specific behavior, macOS, native Windows, and WSL interoperability until the core contract is proven.
