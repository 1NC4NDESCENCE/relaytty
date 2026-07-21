# Security policy

RelayTTY coordinates access to live terminals. Mistakes can expose screen contents, inject commands, repeat non-idempotent actions, or terminate unrelated work.

Please report these privately before opening a public issue:

- input routed to the wrong session or pane;
- terminal capture during a declared sensitive or human-owned interval;
- secrets written into logs, diagnostics, fixtures, or examples;
- cleanup that can affect resources RelayTTY did not create;
- command construction that permits unintended shell interpretation;
- an update or installation path that executes untrusted content unexpectedly.

Use [GitHub private vulnerability reporting](https://github.com/1NC4NDESCENCE/relaytty/security/advisories/new). Do not publish a working exploit or real secret in an issue or discussion.

RelayTTY's ownership protocol is an accident-prevention mechanism, not an operating-system security boundary. Use separate accounts, containers, or machines when actors do not trust one another.
