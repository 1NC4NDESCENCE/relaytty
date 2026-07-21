#!/usr/bin/env bash
set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skill/relaytty/scripts/human-command.sh"

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

printf 'RelayTTY human-command tests passed.\n'
