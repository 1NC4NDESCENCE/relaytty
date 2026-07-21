#!/usr/bin/env bash
set -u

if (( $# == 0 )); then
  printf 'RelayTTY: no command was provided.\n' >&2
  exit 64
fi

if [[ -t 1 ]]; then
  success_color=$'\033[1;32m'
  failure_color=$'\033[1;31m'
  reset_color=$'\033[0m'
else
  success_color=
  failure_color=
  reset_color=
fi

"$@"
command_status=$?

if (( command_status == 0 )); then
  printf '\n%sRelayTTY: SUCCESS%s (exit 0)\n' "$success_color" "$reset_color"
else
  printf '\n%sRelayTTY: FAILED%s (exit %d)\n' \
    "$failure_color" "$reset_color" "$command_status"
fi

printf 'Press Enter to close this terminal and return.\n'
IFS= read -r _
exit "$command_status"
