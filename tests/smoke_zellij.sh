#!/usr/bin/env bash
set -euo pipefail

for required_command in zellij jq; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$required_command" >&2
    exit 1
  fi
done

session_name="relaytty-smoke-$$"
created=false

cleanup() {
  if [[ "$created" == true ]] && zellij list-sessions --short --no-formatting 2>/dev/null | grep -Fxq -- "$session_name"; then
    zellij kill-session "$session_name" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

if zellij list-sessions --short --no-formatting 2>/dev/null | grep -Fxq -- "$session_name"; then
  printf 'refusing to reuse existing session: %s\n' "$session_name" >&2
  exit 1
fi

zellij attach --create-background "$session_name"
created=true

pane_json='[]'
terminal_count=0
for _ in {1..50}; do
  pane_json="$(zellij --session "$session_name" action list-panes --json --all)"
  terminal_count="$(jq '[.[] | select(.is_plugin == false)] | length' <<<"$pane_json")"
  if [[ "$terminal_count" != 0 ]]; then
    break
  fi
  sleep 0.1
done
if [[ "$terminal_count" != 1 ]]; then
  printf 'expected one terminal pane, found %s\n' "$terminal_count" >&2
  exit 1
fi
pane_id="$(jq -r '.[] | select(.is_plugin == false) | .id' <<<"$pane_json")"

wait_for_screen() {
  local expected=$1
  local screen
  for _ in {1..50}; do
    screen="$(zellij --session "$session_name" action dump-screen --pane-id "$pane_id" --full)"
    if [[ "$screen" == *"$expected"* ]]; then
      printf '%s' "$screen"
      return 0
    fi
    sleep 0.1
  done
  printf 'timed out waiting for screen evidence: %s\n' "$expected" >&2
  return 1
}

first_marker="__RELAYTTY_DONE_$$_1"
first_input="{ cd /tmp; export RELAYTTY_SMOKE=ready; }; __relaytty_rc=\$?; printf '\\n${first_marker}:%s\\n' \"\$__relaytty_rc\""
zellij --session "$session_name" action paste --pane-id "$pane_id" -- "$first_input"
zellij --session "$session_name" action send-keys --pane-id "$pane_id" ENTER
wait_for_screen "${first_marker}:0" >/dev/null

second_marker="__RELAYTTY_DONE_$$_2"
second_input="printf 'cwd=%s value=%s\\n' \"\$PWD\" \"\$RELAYTTY_SMOKE\"; __relaytty_rc=\$?; printf '\\n${second_marker}:%s\\n' \"\$__relaytty_rc\""
zellij --session "$session_name" action paste --pane-id "$pane_id" -- "$second_input"
zellij --session "$session_name" action send-keys --pane-id "$pane_id" ENTER
final_screen="$(wait_for_screen "${second_marker}:0")"

if [[ "$final_screen" != *'cwd=/tmp value=ready'* ]]; then
  printf 'shell state did not persist as expected\n' >&2
  exit 1
fi

printf 'RelayTTY Zellij smoke test passed (session %s, terminal pane %s).\n' "$session_name" "$pane_id"
