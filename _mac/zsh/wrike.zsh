#!/usr/bin/env zsh
# ── Wrike task browser (fzf) — run with --help for details ───────────────────
function wrike-browse() {
  local C_BOLD=$'\e[1m'
  local C_DIM=$'\e[2m'
  local C_CYAN=$'\e[36m'
  local C_RESET=$'\e[0m'

  local verbose=0
  local assignee="${WRIKE_ASSIGNEE_NAME}"
  local folder="${WRIKE_FOLDER}"
  local filter_key="${WRIKE_FILTER_KEY}"
  local filter_value="${WRIKE_FILTER_VALUE}"
  local days_ago="${WRIKE_UPDATED_N_DAYSAGO}"
  local extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat <<EOF
${C_BOLD}USAGE${C_RESET}
  wrike-browse [options] [-- wrike-list-options]

  Arguments before -- are handled by wrike-browse.
  Arguments after  -- are passed directly to: wrike tasks list

${C_BOLD}OPTIONS${C_RESET}
  -a, --assignee NAME        Filter by assignee       (overrides \$WRIKE_ASSIGNEE_NAME)
  -f, --folder   NAME        Folder name              (overrides \$WRIKE_FOLDER)
  -k, --filter-key   KEY     customFields key to filter by   (overrides \$WRIKE_FILTER_KEY)
  -F, --filter-value VALUE   customFields value to match     (overrides \$WRIKE_FILTER_VALUE)
  -d, --days-ago N           Updated within N days    (overrides \$WRIKE_UPDATED_N_DAYSAGO)
  -v, --verbose              Show raw JSON in preview pane
  -h, --help                 Show this help

  Note: --filter-key and --filter-value must both be set to apply a customField filter.
  Note: --assignee and --folder are optional; omit to fetch all accessible tasks.

${C_BOLD}PASS-THROUGH (after --)${C_RESET}
  Any flags after -- are forwarded verbatim to: wrike tasks list
  Example: -- --status Active --limit 200

${C_BOLD}ENV VARS${C_RESET}
  Optional (set in sensitive-zshrc or export before calling):
    WRIKE_ASSIGNEE_NAME      Filter by assignee
    WRIKE_FOLDER             Folder name
    WRIKE_FILTER_KEY         customFields key to filter by
    WRIKE_FILTER_VALUE       customFields value to match
    WRIKE_UPDATED_N_DAYSAGO  Only tasks updated within N days

${C_BOLD}DEPENDENCIES${C_RESET}
  wrike   Wrike CLI
  jq      JSON processor    https://jqlang.github.io/jq/
  fzf     Fuzzy finder      https://github.com/junegunn/fzf
  awk     Text processor    built-in on macOS/Linux
  lynx    Terminal browser  https://lynx.browser.org/  (renders HTML descriptions)

${C_BOLD}EXAMPLES${C_RESET}
  wrike-browse
  wrike-browse -v
  wrike-browse --assignee "John Doe" --folder "Sprint 42"
  wrike-browse -a "John Doe" -f "Sprint 42" -d 14
  wrike-browse -a "Jane" -f "Backlog" -k "Monthly Release" -F "2024.04"
  wrike-browse -- --status Active --limit 200
  wrike-browse -a "John" -f "Sprint" -- --status Active

${C_BOLD}KEYBINDINGS${C_RESET}
  shift-up / shift-down   Scroll preview
  enter                   Open selected task in browser (macOS)
  ctrl-p                  Open details in pager (selectable/copiable, no borders)
EOF
        return 0
        ;;
      -v|--verbose)     verbose=1; shift ;;
      -a|--assignee)    assignee="$2"; shift 2 ;;
      -f|--folder)      folder="$2"; shift 2 ;;
      -k|--filter-key)  filter_key="$2"; shift 2 ;;
      -F|--filter-value) filter_value="$2"; shift 2 ;;
      -d|--days-ago)    days_ago="$2"; shift 2 ;;
      --)               shift; extra_args=("$@"); break ;;
      *) printf "wrike-browse: unknown option: %s\n  Run with --help for usage.\n" "$1" >&2; return 1 ;;
    esac
  done

  # Sync display variables with any overrides passed in extra_args (after --)
  local _i
  for (( _i=1; _i<=${#extra_args[@]}; _i++ )); do
    case "${extra_args[$_i]}" in
      --assignee) (( _i < ${#extra_args[@]} )) && assignee="${extra_args[$((_i+1))]}" ;;
      --folder)   (( _i < ${#extra_args[@]} )) && folder="${extra_args[$((_i+1))]}" ;;
    esac
  done

  if [[ -n "$days_ago" && ! "$days_ago" =~ ^[0-9]+$ ]]; then
    printf "wrike-browse: --days-ago requires a positive integer, got: %s\n" "$days_ago" >&2
    return 1
  fi

  local dep
  local missing_deps=()
  for dep in wrike jq fzf awk lynx; do
    command -v "$dep" &>/dev/null || missing_deps+=("$dep")
  done
  if (( ${#missing_deps[@]} )); then
    printf "wrike-browse: missing dependencies: %s\n" "${(j:, :)missing_deps}" >&2
    return 1
  fi

  local tmpfile
  tmpfile=$(mktemp -t wrike-browse) || { printf "wrike-browse: failed to create temp file\n" >&2; return 1; }
  local filterfile="${tmpfile}.jq"
  find "$(dirname "$tmpfile")" -maxdepth 1 -name 'wrike-browse.*' -not -newer "$tmpfile" -delete 2>/dev/null

  {
    local wrike_args=()
    [[ -n "$assignee" ]] && wrike_args+=(--assignee "$assignee")
    [[ -n "$folder" ]]   && wrike_args+=(--folder "$folder")

    printf "Fetching tasks..." >&2
    wrike tasks list --json "${wrike_args[@]}" "${extra_args[@]}" > "$tmpfile" \
      || { printf " failed\n" >&2; return 1; }
    printf " done\n" >&2

    local jq_filter='.[]'
    [[ -n "$filter_key" && -n "$filter_value" ]] && jq_filter+=" | select(.customFields[\"${filter_key}\"] == \"${filter_value}\")"
    [[ -n "$days_ago" ]] && jq_filter+=" | select(.updatedDate | fromdateiso8601 > (now - 86400 * ${days_ago}))"

    local header="  Assignee: ${assignee:-any}  |  Folder: ${folder:-any}  |  Filter: ${filter_key:+${filter_key}=}${filter_value:-none}  |  Updated: last ${days_ago:-any} day(s)"

    local json_section=""
    (( verbose )) && json_section="jq -C --arg id {1} '.[] | select(.id == \$id)' \"${tmpfile}\""

    # Single-quoted heredoc: no shell expansion, no escaping needed — pure jq
    cat <<'EOF' > "$filterfile"
.[] | select(.id == $id) |
$bold + .title + $reset, "",
$dim + "Assignee:   " + $reset + $assignee,
$dim + "Status:     " + $reset + .status,
$dim + "Type:       " + $reset + (.type // "Task"),
$dim + "Importance: " + $reset + (.importance // "-"),
$dim + "Updated:    " + $reset + (.updatedDate[:16] | gsub("T"; " ")),
$dim + "Created:    " + $reset + (.createdDate[:16] | gsub("T"; " ")),
$dim + "Requestor:  " + $reset + (.customFields.Requestor // "-"),
$dim + "Priority:   " + $reset + (.customFields.Priority // "-"),
$dim + "Link:       " + $reset + $cyan + .permalink + $reset,
"", $dim + "-----------------" + $reset
EOF

    local detail_cmd
    detail_cmd=$(cat <<EOF
  jq -r -f "${filterfile}" --arg id {1} --arg assignee "${assignee}" \
     --arg bold "${C_BOLD}" --arg dim "${C_DIM}" --arg cyan "${C_CYAN}" --arg reset "${C_RESET}" \
     "${tmpfile}"
  jq -r --arg id {1} '.[] | select(.id == \$id) | .description // "none"' "${tmpfile}" \
    | lynx -dump -nolist -assume_charset=utf-8 -display_charset=utf-8 -stdin 2>/dev/null
EOF
)

    local preview_cmd="
      ${detail_cmd}
      printf '\n\n\n\n\n\n\n\n\n\n'
      ${json_section}
    "

    local bind_pager="execute({ ${preview_cmd} } | LESSCHARSET=utf-8 less -R)"

    local -a tips=(
      "Press enter to open the selected ticket in your browser"
      "Press ctrl-p to open task details in a scrollable pager"
      "Press shift-up / shift-down to scroll the preview pane"
      "Run with -v to show raw JSON at the bottom of the preview"
      "Run with -d 7 to limit results to tasks updated in the last 7 days"
      "Run with --help to see all options and keybindings"
    )
    local tip="${tips[$(( RANDOM % ${#tips[@]} + 1 ))]}"

    local list_query
    list_query=$(cat <<EOF
[${jq_filter}] | sort_by(.updatedDate) | reverse | .[] | [
  .id,
  ((.permalink | capture("id=(?<pid>[0-9]+)") | .pid) // ""),
  (.customFields.Priority // "-"),
  .status,
  (.type // "Task"),
  (.updatedDate[:16] | gsub("T"; " ")),
  .title
] | @tsv
EOF
)

    local selected
    selected=$(
      jq -r "$list_query" "$tmpfile" \
      | awk -F'\t' '{printf "%s\t%-12s  %-10s  %-20s  %-14s  %-16s  %s\n", $1, $2, substr($3,1,10), substr($4,1,20), substr($5,1,14), $6, $7}' \
      | fzf --ansi --height 90% \
          --layout reverse \
          --delimiter $'\t' \
          --with-nth '2..' \
          --header "$header" \
          --preview-window 'down,75%,border-top,wrap' \
          --preview "$preview_cmd" \
          --footer "${C_DIM}  Tip: ${tip}${C_RESET}" \
          --bind 'shift-up:preview-up,shift-down:preview-down' \
          --bind "ctrl-p:${bind_pager}" \
      | cut -f1
    )

    [[ -z "$selected" ]] && return 0
    local permalink
    permalink=$(jq -r --arg id "$selected" '.[] | select(.id == $id) | .permalink' "$tmpfile")
    [[ -n "$permalink" ]] && open "$permalink"
  } always {
    rm -f "$tmpfile" "$filterfile"
  }
}
