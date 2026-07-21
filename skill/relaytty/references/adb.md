# ADB and Android procedure

An Android workflow contains at least two identities:

- the local Zellij session and pane;
- the selected Android device or emulator.

Never infer one from the other. Record the device serial explicitly and prefer `ANDROID_SERIAL` or `adb -s SERIAL ...` when multiple devices may exist.

## Choose the terminal shape

- Use a **persistent local shell** when repeated independent `adb` commands share local `cwd`, environment, or helper functions.
- Use an **interactive application** when entering `adb shell` and preserving remote Android shell state.
- Use a **direct job** for one long-running `adb` command whose own lifecycle is the completion signal.

Once `adb shell` owns the foreground, local-shell acknowledgement syntax is no longer valid. Treat it as an application-specific nested shell and use a marker appropriate to that remote shell only when doing so is safe.

## Track independent state

At minimum distinguish:

- local session and pane ID;
- ADB server availability;
- selected device serial;
- device connection state such as `device`, `offline`, or `unauthorized`;
- local versus remote shell foreground;
- remote `cwd`, user, and privilege state;
- current human or agent owner.

A live pane does not prove a live device. A reconnected device with the same serial does not prove the old remote shell survived.

## Recovery rules

- Do not silently choose a different device when the selected serial disappears.
- Do not repeatedly send a command after an ADB timeout without inspecting device and pane state.
- Treat authorization prompts and privilege escalation as human handoff boundaries.
- After reconnect or human intervention, re-query device state and determine whether the nested shell is still foreground before sending input.
