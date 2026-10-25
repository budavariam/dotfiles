#!/usr/bin/env bats
# Tests for sketchybar/.config/sketchybar/plugins/ai_sessions.py
# Output contract: H<TAB>header, R<TAB>pid<TAB>sid<TAB>status<TAB>needs<TAB>cwd<TAB>label, F<TAB>footer.
# Fake HOME, AI_FLAG_DIR and AI_SL_DIR keep the run away from the real ~/.claude and /tmp.

PLUGIN="$BATS_TEST_DIRNAME/../../sketchybar/.config/sketchybar/plugins/ai_sessions.py"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export AI_FLAG_DIR="$BATS_TEST_TMPDIR/flags"
  export AI_SL_DIR="$BATS_TEST_TMPDIR/sl"
  mkdir -p "$HOME/.claude/sessions" "$AI_FLAG_DIR" "$AI_SL_DIR"
  # Fake ps: process tables come from fixtures, never the real process list
  export PS_COMM="$BATS_TEST_TMPDIR/ps-comm" PS_ARGS="$BATS_TEST_TMPDIR/ps-args"
  : > "$PS_COMM"; : > "$PS_ARGS"
  export AI_PS="$BATS_TEST_TMPDIR/ps"
  printf '#!/bin/sh\ncase "$*" in *etime*) cat "$PS_ARGS" ;; *) cat "$PS_COMM" ;; esac\n' > "$AI_PS"
  chmod +x "$AI_PS"
  export AI_TOOLS="" AI_SORT_BY=idle AI_SORT_DIR=asc
  PIDS=()
}

teardown() {
  for p in "${PIDS[@]}"; do pkill -P "$p" 2>/dev/null; kill "$p" 2>/dev/null; done
  return 0
}

# add_session <sid> [json fields after status, e.g. ',"name":"x"'] [status]
add_session() {
  sleep 60 &
  local pid=$!
  PIDS+=("$pid")
  printf '{"pid":%s,"sessionId":"%s","status":"%s"%s}' "$pid" "$1" "${3:-idle}" "${2-}" \
    > "$HOME/.claude/sessions/$pid.json"
  LAST_PID=$pid
}

now_ms() { echo $(( $(date +%s) * 1000 )); }

run_plugin() { run python3 -I "$PLUGIN"; }

# col <line type> <field number>: that field of every line of the type
col() { printf '%s\n' "$output" | awk -F'\t' -v t="$1" -v n="$2" '$1 == t { print $n }'; }
order() { col R 3 | paste -sd, -; }

@test "no sessions: header and zeroed footer only" {
  run_plugin
  [ "$status" -eq 0 ]
  [ -z "$(col R 1)" ]
  [ "$(col F 2)" = "0 sessions  ·  0 busy  ·  0 idle  ·  0 waiting" ]
}

@test "header line: H, marker, then the column titles" {
  run_plugin
  h=$(col H 2)
  [[ "$h" == "·  TOOL  APP"* ]]
  [[ "$h" == *"SESSION"*"BRANCH"*"MODEL"*"CTX"*"AGE"*"IDLE"*"PID" ]]
}

@test "row line: R, pid, sid, status, needs, cwd, label" {
  mkdir -p "$BATS_TEST_TMPDIR/proj"
  add_session sid-1 ",\"cwd\":\"$BATS_TEST_TMPDIR/proj\",\"name\":\"my session\"" busy
  run_plugin
  line=$(printf '%s\n' "$output" | grep '^R')
  [ "$(printf '%s' "$line" | awk -F'\t' '{print NF}')" -eq 7 ]
  [ "$(col R 2)" = "$LAST_PID" ]
  [ "$(col R 3)" = "sid-1" ]
  [ "$(col R 4)" = "busy" ]
  [ "$(col R 5)" = "0" ]
  [ "$(col R 6)" = "$BATS_TEST_TMPDIR/proj" ]
  label=$(col R 7)
  [[ "$label" == *"Claude"* && "$label" == *"my session"* && "$label" == *"$LAST_PID" ]]
}

@test "session name defaults to the cwd basename" {
  mkdir -p "$BATS_TEST_TMPDIR/some-project"
  add_session sid-1 ",\"cwd\":\"$BATS_TEST_TMPDIR/some-project\""
  run_plugin
  [[ "$(col R 7)" == *"some-project"* ]]
}

@test "empty cwd and name never produce empty fields" {
  add_session sid-1
  run_plugin
  [ "$(col R 6)" = "-" ]
  [ "$(printf '%s\n' "$output" | grep '^R' | awk -F'\t' '{for(i=1;i<=NF;i++) if($i=="") e++} END{print e+0}')" -eq 0 ]
}

@test "tabs in session fields are replaced so the row keeps 7 fields" {
  add_session 'sid\t1' ',"name":"a\tb"'
  run_plugin
  [ "$(printf '%s\n' "$output" | grep '^R' | awk -F'\t' '{print NF}')" -eq 7 ]
  [ "$(col R 3)" = "sid 1" ]
}

@test "dead pids, malformed and pid-less files are skipped" {
  add_session live
  sleep 0.1 & dead=$!
  kill "$dead"; wait "$dead" || true
  printf '{"pid":%s,"sessionId":"dead","status":"busy"}' "$dead" > "$HOME/.claude/sessions/$dead.json"
  echo 'not json' > "$HOME/.claude/sessions/bad.json"
  echo '{"sessionId":"nopid"}' > "$HOME/.claude/sessions/nopid.json"
  run_plugin
  [ "$(order)" = "live" ]
  [ "$(col F 2)" = "1 sessions  ·  0 busy  ·  1 idle  ·  0 waiting" ]
}

@test "footer counts sessions, busy, idle and waiting" {
  add_session a "" busy
  add_session b "" busy
  add_session c "" idle
  add_session d "" idle
  touch "$AI_FLAG_DIR/c"
  run_plugin
  [ "$(col F 2)" = "4 sessions  ·  2 busy  ·  2 idle  ·  1 waiting" ]
}

@test "needs-action flag file sets needs=1 only for that session" {
  add_session flagged
  add_session plain
  touch "$AI_FLAG_DIR/flagged"
  run_plugin
  [ "$(printf '%s\n' "$output" | awk -F'\t' '$3=="flagged"{print $5}')" = "1" ]
  [ "$(printf '%s\n' "$output" | awk -F'\t' '$3=="plain"{print $5}')" = "0" ]
}

@test "statusline file supplies model and context percent" {
  add_session sid-1
  echo '{"model":"opus-4-test","used_pct":42.4}' > "$AI_SL_DIR/sid-1.json"
  run_plugin
  label=$(col R 7)
  [[ "$label" == *"opus-4-test"* && "$label" == *"42%"* ]]
}

@test "without statusline file, model and context come from the transcript tail" {
  add_session sid-1
  mkdir -p "$HOME/.claude/projects/p"
  {
    echo '{"type":"assistant","message":{"model":"claude-old-1","usage":{"input_tokens":1}}}'
    echo '{"type":"assistant","message":{"model":"claude-sonnet-x","usage":{"input_tokens":10000,"cache_read_input_tokens":30000,"cache_creation_input_tokens":10000}}}'
    echo '{"type":"user"}'
  } > "$HOME/.claude/projects/p/sid-1.jsonl"
  run_plugin
  label=$(col R 7)
  [[ "$label" == *"sonnet-x"* && "$label" == *"~50k"* ]]
}

@test "no model information shows dashes" {
  add_session sid-1
  run_plugin
  [[ "$(col R 7)" == *"  -  "*"  -  "* ]]
}

@test "age and idle are formatted from startedAt / updatedAt" {
  n=$(( $(date +%s) ))
  add_session sid-1 ",\"startedAt\":$(( (n - 3*3600) * 1000 )),\"updatedAt\":$(( (n - 300) * 1000 ))"
  run_plugin
  label=$(col R 7)
  [[ "$label" == *"3h00m"* && "$label" == *"5m"* ]]
}

@test "default order is idle ascending (most recently active first)" {
  n=$(date +%s)
  add_session old ",\"updatedAt\":$(( (n - 1000) * 1000 ))"
  add_session fresh ",\"updatedAt\":$(( (n - 10) * 1000 ))"
  add_session mid ",\"updatedAt\":$(( (n - 100) * 1000 ))"
  run_plugin
  [ "$(order)" = "fresh,mid,old" ]
}

@test "AI_SORT_DIR=desc reverses the order" {
  n=$(date +%s)
  add_session old ",\"updatedAt\":$(( (n - 1000) * 1000 ))"
  add_session fresh ",\"updatedAt\":$(( (n - 10) * 1000 ))"
  add_session mid ",\"updatedAt\":$(( (n - 100) * 1000 ))"
  AI_SORT_DIR=desc run_plugin
  [ "$(order)" = "old,mid,fresh" ]
}

@test "unknown AI_SORT_BY falls back to idle ascending" {
  n=$(date +%s)
  add_session old ",\"updatedAt\":$(( (n - 1000) * 1000 ))"
  add_session fresh ",\"updatedAt\":$(( (n - 10) * 1000 ))"
  AI_SORT_BY=bogus run_plugin
  [ "$(order)" = "fresh,old" ]
}

@test "AI_SORT_BY=ctx compares numerically (9 < 10 < 100)" {
  add_session s100; add_session s9; add_session s10
  echo '{"used_pct":100}' > "$AI_SL_DIR/s100.json"
  echo '{"used_pct":9}' > "$AI_SL_DIR/s9.json"
  echo '{"used_pct":10}' > "$AI_SL_DIR/s10.json"
  AI_SORT_BY=ctx run_plugin
  [ "$(order)" = "s9,s10,s100" ]
  AI_SORT_BY=ctx AI_SORT_DIR=desc run_plugin
  [ "$(order)" = "s100,s10,s9" ]
}

@test "AI_SORT_BY=age compares numerically (2h before 10h before 2d)" {
  n=$(date +%s)
  add_session d2 ",\"startedAt\":$(( (n - 2*86400) * 1000 ))"
  add_session h2 ",\"startedAt\":$(( (n - 2*3600) * 1000 ))"
  add_session h10 ",\"startedAt\":$(( (n - 10*3600) * 1000 ))"
  AI_SORT_BY=age run_plugin
  [ "$(order)" = "h2,h10,d2" ]
}

@test "AI_SORT_BY=session sorts names naturally and case-insensitively" {
  add_session a ',"name":"s10"'
  add_session b ',"name":"s2"'
  add_session c ',"name":"S1"'
  AI_SORT_BY=session run_plugin
  [ "$(order)" = "c,b,a" ]
}

@test "AI_SORT_BY=pid sorts by process id" {
  add_session a; first=$LAST_PID
  add_session b; second=$LAST_PID
  AI_SORT_BY=pid AI_SORT_DIR=desc run_plugin
  [ "$(col R 2 | head -1)" = "$(( first > second ? first : second ))" ]
}

# ps_args <pid> <ppid> <etime> <args...>: a line of the fake `ps -o pid,ppid,etime,args` table
ps_args() { printf '%s %s %s %s\n' "$1" "$2" "$3" "${*:4}" >> "$PS_ARGS"; }

@test "Claude row host comes from the ancestor chain of the process table" {
  add_session sid-1
  printf '%s 900 /bin/zsh\n900 800 login\n800 1 /Applications/iTerm.app/Contents/MacOS/iTerm2\n' "$LAST_PID" > "$PS_COMM"
  run_plugin
  [[ "$(col R 7)" == *"iTerm"* ]]
}

@test "AI_TOOLS rows: matched process becomes a running row with its own sid" {
  ps_args 4242 1 01:05 sleep 3571
  ps_args 4243 1 00:01 unrelated thing
  AI_TOOLS=$'Fake=^sleep 3571$\nbroken line\n=nolabel\nBad=(' run_plugin
  [ "$(col R 2)" = "4242" ]
  [ "$(col R 3)" = "p4242" ]
  [ "$(col R 4)" = "running" ]
  [ "$(col R 5)" = "0" ]
  label=$(col R 7)
  [[ "$label" == *"Fake"* && "$label" == *"1m"* ]]
  [ "$(col F 2)" = "1 sessions  ·  0 busy  ·  1 idle  ·  0 waiting" ]
}

@test "AI_TOOLS: a child of a process matching the same tool is skipped" {
  ps_args 500 1 10:00 mytool --main
  ps_args 501 500 10:00 mytool --worker
  ps_args 600 1 10:00 mytool --other
  AI_TOOLS='My=mytool' run_plugin
  [ "$(col R 2 | sort | paste -sd, -)" = "500,600" ]
}

@test "AI_TOOLS Ollama row extracts the model from the command line" {
  ps_args 700 1 00:30 /opt/homebrew/bin/ollama run llama3.2
  AI_TOOLS='Ollama=ollama run' run_plugin
  [[ "$(col R 7)" == *"Ollama"*"llama3.2"* ]]
}

@test "AI_TOOLS rows and Claude sessions are counted together in the footer" {
  add_session a "" busy
  ps_args 4242 1 00:30 sleep 3571
  AI_TOOLS='Fake=^sleep 3571$' run_plugin
  [ "$(col R 1 | grep -c .)" -eq 2 ]
  [ "$(col F 2)" = "2 sessions  ·  1 busy  ·  1 idle  ·  0 waiting" ]
}

@test "parse_etime: days and hours format into the age column" {
  ps_args 4242 1 2-03:00:00 sleep 3571
  AI_TOOLS='Fake=sleep 3571' run_plugin
  [[ "$(col R 7)" == *"2d3h"* ]]
}
