# Testing RelayTTY

RelayTTY should be tested as a small coordination system, not as a collection of shell snippets. A command returning zero is weak evidence: it does not prove that it reached the intended pane, ran once, preserved the right state, respected ownership, or left unrelated sessions alone.

## The testing model

Start from the contract:

```text
request
  -> select or decline RelayTTY
  -> create/discover typed identities
  -> choose mode and owner
  -> act once on the intended terminal
  -> establish what happened
  -> hand off, retain, or clean up safely
```

Every arrow is a possible product failure. Tests should make each transition observable and vary the state on both sides. This produces better coverage than accumulating examples of commands that happened to work.

## General principles

### Test semantics, not implementation spelling

The stable promise is “route input to the recorded terminal pane,” not “this exact Zellij command exists.” Backend conformance tests may assert CLI details, while higher-level scenarios should assert preserved state, ownership, and outcomes. This lets a backend command change without silently changing the product contract.

### Test dimensions independently

Process lifetime, PTY lifetime, discovery, shell state, foreground application, ownership, observation freshness, and action certainty are related but distinct. A useful test deliberately breaks one while keeping the others—for example, keep the Zellij session alive while the device disconnects, or keep the process alive while the client detaches.

### Prefer stronger oracles

An oracle is how a test knows what happened. Prefer structured metadata or an application protocol, then unique controlled acknowledgements, then bounded screen snapshots, and finally human confirmation. Screen text alone is easy to fool with redraws, wrapping, old output, or an application that prints marker-like text.

### Negative behavior is part of correctness

RelayTTY must decline ordinary one-shot work, avoid capture during human ownership, refuse ambiguous targeting, and preserve uncertain state rather than “recover” destructively. These are not edge cases; they prevent the tool from making normal work slower or dangerous.

### Exercise uncertainty, not only success

Interrupt the observer after input may have been delivered. Delay acknowledgements. Close a client without killing the process. Change focus. Open plugin panes with colliding numeric IDs. Disconnect and reconnect ADB. The desired result is often not automatic success—it is a bounded, truthful state such as “action outcome unknown; no replay performed.”

### Make failures reproducible without collecting secrets

Test fixtures should use synthetic commands, devices, files, and credentials. Diagnostics should record versions, typed IDs, lifecycle transitions, mode, owner, and timing, but exclude screen contents, command history, environment values, and input unless a test explicitly uses non-sensitive fixtures.

## Test layers

| Layer | Main question | Examples |
|---|---|---|
| Selection evaluations | Should the skill activate and which mode should it choose? | one-shot decline, debugger, persistent shell, sensitive editor |
| Policy/model tests | Are forbidden transitions rejected? | two writers, capture while human-owned, replay after ambiguity |
| Backend conformance | Can a backend realize the contract? | create/discover, typed pane identity, explicit input, attach, cleanup |
| Application recipes | Does application state stay distinct from terminal state? | ADB offline/unauthorized, nested shell, later LLDB prompt states |
| Fault injection | Is uncertainty handled honestly and safely? | timeout before acknowledgement, client crash, pane exit, stale ID |
| Compatibility | Which exact combinations deserve a support claim? | clean Linux install, shell variants, Zellij versions, later macOS |
| Human usability | Can a person understand and control the relay? | first-run setup, attach, explicit hand-back, recovery instructions |

No single layer substitutes for another. A live end-to-end demo proves integration on one happy path; it cannot efficiently cover selection boundaries or injected failures. Model tests prove rules, but not that a backend actually obeys them.

## Scenario design

Write each scenario with:

- preconditions and exact versions;
- initial terminal, application, and ownership state;
- the event or request;
- allowed state transitions;
- forbidden side effects;
- the strongest available oracle;
- cleanup ownership;
- artifacts safe to retain after failure.

For every positive scenario, look for a meaningful neighbor that should behave differently. “Keep this REPL open” should activate; “run this formatter once” should not. “User has handed the pane back” may allow capture; “user detached without hand-back” must not.

## Current prototype tests

[`evals/scenarios.yaml`](evals/scenarios.yaml) records the first selection and mode expectations. These require an agent-evaluation runner before they become automated gates.

[`tests/smoke_zellij.sh`](tests/smoke_zellij.sh) is a local backend smoke test. It creates a collision-resistant session, uses bounded polling to discover exactly one non-plugin terminal pane, sends two separately acknowledged commands, verifies that `cwd` and an exported value persist, and removes only its own session. It intentionally does not claim to test human handoff, ADB, fault recovery, or skill activation.

[`tests/test_human_command.sh`](tests/test_human_command.sh) verifies the one-shot human-command wrapper's success and failure messages, preserved exit status, and explicit close instruction. The regression exists because a raw Zellij command pane can remain held after exit and make Enter rerun a privileged command.

## Publication gates

Before the first public release:

1. Static skill validation passes from a clean checkout.
2. Selection evaluations cover positive, negative, and ambiguous requests.
3. Backend conformance passes repeatedly on the supported Linux matrix.
4. Fault tests cover ambiguous delivery, client detach, pane exit, stale identity, and failed cleanup.
5. Human-handoff tests demonstrate zero automated input and capture during ownership.
6. The ADB recipe covers multiple devices, offline, unauthorized, disconnect, and nested-shell loss.
7. A new user completes installation and the demonstration from the README without private coaching.
8. Diagnostics are reviewed using canary secrets that must never appear in retained artifacts.
9. Support claims name exact tested versions and separate automated from manual evidence.
10. The README demonstration is reproducible, reviewed for secrets, and accompanied by a transcript or captions.

Release confidence comes from different kinds of evidence agreeing, not from a large test count. When a production bug appears, first ask which state transition or oracle the suite failed to represent; then add that missing idea as a regression test.
