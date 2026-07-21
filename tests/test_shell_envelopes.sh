#!/usr/bin/env bash
set -euo pipefail

tested=0
probe='{ cd /tmp; export RELAYTTY_SHELL_PROBE=ready; }; __relaytty_rc=$?; printf "rc=%s cwd=%s value=%s\n" "$__relaytty_rc" "$PWD" "$RELAYTTY_SHELL_PROBE"'
failure_probe='false; __relaytty_rc=$?; printf "rc=%s\n" "$__relaytty_rc"'

for shell_name in bash dash mksh zsh; do
  if ! command -v "$shell_name" >/dev/null 2>&1; then
    continue
  fi

  state_output="$("$shell_name" -c "$probe")"
  if [[ "$state_output" != 'rc=0 cwd=/tmp value=ready' ]]; then
    printf '%s failed the state-preservation grammar probe: %s\n' "$shell_name" "$state_output" >&2
    exit 1
  fi

  failure_output="$("$shell_name" -c "$failure_probe")"
  if [[ "$failure_output" != 'rc=1' ]]; then
    printf '%s failed the exit-status grammar probe: %s\n' "$shell_name" "$failure_output" >&2
    exit 1
  fi

  printf 'Bourne-style envelope grammar passed under %s.\n' "$shell_name"
  tested=$((tested + 1))
done

if (( tested == 0 )); then
  printf 'no Bourne-style shells were available to test\n' >&2
  exit 1
fi

printf 'RelayTTY shell-envelope probes passed for %d installed shell(s).\n' "$tested"
