#!/usr/bin/env bash
set -euo pipefail
EVIDENCE=/Users/alejandroarias/.no-mistakes/evidence/01M4NJNH4EKJ1VG5WD1CWH97P6
LAB=$(sed -n '1p' tests/.crew-state-live-lab)
SOCKET_DIR=$(sed -n '2p' tests/.crew-state-live-lab)
export TMUX_TMPDIR="$SOCKET_DIR"
export TMUX="$(tmux -L fm-lab display-message -p -t primary '#{socket_path}'),0,0"
export FM_HOME="$LAB"
unset FM_ROOT_OVERRIDE FM_STATE_OVERRIDE FM_DATA_OVERRIDE FM_CONFIG_OVERRIDE FM_PROJECTS_OVERRIDE FM_GATE_REFUSE_BYPASS
cleanup() {
  tmux -L fm-lab kill-server 2>/dev/null || true
  bin/fm-lab-home.sh teardown "$LAB"
  rm -rf "$LAB"
}
trap cleanup EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
mkdir -p "$LAB/projects/crew"
git -C "$LAB/projects/crew" init -q
git -C "$LAB/projects/crew" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m fixture
git -C "$LAB/projects/crew" checkout -q --detach
WINDOW=$(tmux -L fm-lab display-message -p -t primary '#{window_name}')
printf 'window=primary:%s\nworktree=%s\nkind=ship\nharness=claude\nbackend=tmux\n' "$WINDOW" "$LAB/projects/crew" > "$LAB/state/crew.meta"
ENDPOINT=$(bash -c '. bin/fm-backend.sh; fm_backend_agent_state tmux "$1"' _ "primary:$WINDOW")
printf 'Private endpoint: %s; grid: %s; current command: %s\n' "$ENDPOINT" "$(tmux -L fm-lab display-message -p -t primary '#{pane_width}x#{pane_height}')" "$(tmux -L fm-lab display-message -p -t primary '#{pane_current_command}')"
[ "$ENDPOINT" = alive ]
# The real print-mode Claude process waits for input; this disposable record
# supplies the public semantic state input for the reader under validation.
bin/fm-busy-event.sh arm "$LAB/state" crew --state idle --source fm-recovery --event idle-fixture >/dev/null
read_state() {
  local label=$1 expected=$2 out
  out=$(bash bin/fm-crew-state.sh crew)
  printf '%s\n%s\n' "$label" "$out"
  case "$out" in "$expected"*) ;; *) return 1 ;; esac
}
printf 'needs-decision [key=q1]: which database?\ncaptain-held [key=q1]: tracked by crew-db\n' > "$LAB/state/crew.status"
read_state 'Before backlog hold exists' 'state: parked · source: status-log · captain-held: tracked by crew-db'
printf 'Base version, same live endpoint and input:\n'
BASE=$(bash bin/.fm-crew-state-baseline-gate.sh crew)
printf '%s\n' "$BASE"
case "$BASE" in 'state: unknown · source: none'*) ;; *) exit 1 ;; esac
cat > "$LAB/data/backlog.md" <<'EOF'
## In flight

## Queued
- [ ] crew-db - Choose the database (repo: sample) (kind: captain) (hold: which database?) (hold-kind: captain)

## Done
EOF
read_state 'After matching backlog hold exists' 'state: parked · source: status-log · captain-held: tracked by crew-db'
printf 'The captain is reviewing the options.\n\n' >> "$LAB/state/crew.status"
read_state 'After continuation prose and blank lines' 'state: parked · source: status-log · captain-held: tracked by crew-db'
printf 'needs-decision [key=q2]: choose another option\n' >> "$LAB/state/crew.status"
read_state 'A new decision takes precedence over the old held declaration' 'state: parked · source: status-log · choose another option'
printf 'paused: waiting for upstream release\n' > "$LAB/state/crew.status"
read_state 'Existing external pause still reports paused' 'state: paused · source: status-log · waiting for upstream release'
printf 'blocked [key=q3]: missing test input\n' > "$LAB/state/crew.status"
read_state 'Existing blocker still reports blocked' 'state: blocked · source: status-log · missing test input'
printf 'captain-held [key=q1]: tracked by crew-db\n' > "$LAB/state/crew.status"
bin/fm-busy-event.sh apply "$LAB/state" crew unknown --current-gen --source fm-recovery --event unknown-fixture
read_state 'Unknown semantic state cannot be hidden by a held status' 'state: unknown · source: pane · harness state unavailable'
bin/fm-busy-event.sh apply "$LAB/state" crew busy --current-gen --source fm-recovery --event busy-fixture
read_state 'Authoritative busy state outranks held status' 'state: working · source: pane · harness busy'
bin/fm-busy-event.sh apply "$LAB/state" crew idle --current-gen --source fm-recovery --event idle-fixture
tmux -L fm-lab kill-server
read_state 'Missing endpoint cannot revive a stale held declaration' 'state: unknown · source: none · backend target gone'
printf 'Disposable lab and its private tmux server removed by EXIT cleanup.\n'
