#!/usr/bin/env bash
set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skill/relaytty/scripts/human-command.sh"

for shell_name in sh dash bash zsh; do
  if ! command -v "$shell_name" >/dev/null 2>&1; then
    continue
  fi
  portable_output="$(printf '\n' | "$shell_name" "$helper" true)"
  if [[ "$portable_output" != *'RelayTTY: SUCCESS (exit 0)'* ]]; then
    printf 'helper failed under %s\n' "$shell_name" >&2
    exit 1
  fi
done

success_output="$(printf '\n' | "$helper" true)"
if [[ "$success_output" != *'RelayTTY: SUCCESS (exit 0)'* ]]; then
  printf 'missing success result\n' >&2
  exit 1
fi
if [[ "$success_output" != *'Press Enter to close this terminal and return.'* ]]; then
  printf 'missing close instruction\n' >&2
  exit 1
fi

set +e
failure_output="$(printf '\n' | "$helper" sh -c 'exit 7')"
failure_status=$?
set -e
if [[ "$failure_status" != 7 ]]; then
  printf 'expected status 7, got %s\n' "$failure_status" >&2
  exit 1
fi
if [[ "$failure_output" != *'RelayTTY: FAILED (exit 7)'* ]]; then
  printf 'missing failure result\n' >&2
  exit 1
fi

printf 'RelayTTY portable human-command tests passed.\n'
