# ── Wrike task browser (fzf) ──────────────────────────────────────────────────
# ENV vars (required — set in sensitive-zshrc or export before calling):
#   WRIKE_ASSIGNEE_NAME           - filter by assignee
#   WRIKE_FOLDER                  - folder name
# ENV vars (optional):
#   WRIKE_MONTHLY_RELEASE_VERSION - release version filter
#   WRIKE_RELEASE_FIELD_NAME      - release custom field name
#   WRIKE_UPDATED_N_DAYSAGO       - only tasks updated within N days
# Keybindings: shift-up/down scrolls preview, enter opens task in browser
function wrike-browse() {
  local missing_deps=()
  for dep in wrike jq fzf awk lynx; do
    command -v "$dep" &>/dev/null || missing_deps+=("$dep")
  done
  if (( ${#missing_deps[@]} )); then
    printf "wrike-browse: missing dependencies: %s\n" "${(j:, :)missing_deps}" >&2
    return 1
  fi

  local missing=()
  [[ -z "${WRIKE_ASSIGNEE_NAME}" ]] && missing+=(WRIKE_ASSIGNEE_NAME)
  [[ -z "${WRIKE_FOLDER}" ]]        && missing+=(WRIKE_FOLDER)
  if (( ${#missing[@]} )); then
    printf "wrike-browse: missing required env vars: %s\n" "${(j:, :)missing}" >&2
    printf "  Set them in sensitive-zshrc or export before calling.\n" >&2
    return 1
  fi

  local assignee="${WRIKE_ASSIGNEE_NAME}"
  local folder="${WRIKE_FOLDER}"
  local release="${WRIKE_MONTHLY_RELEASE_VERSION}"
  local release_field="${WRIKE_RELEASE_FIELD_NAME}"
  local days_ago="${WRIKE_UPDATED_N_DAYSAGO}"

  local tmpfile; tmpfile=$(mktemp -t wrike-browse)
  find /tmp -maxdepth 1 -name 'wrike-browse.*' -not -newer "$tmpfile" -delete 2>/dev/null

  {
    printf "Fetching tasks..." >&2
    wrike tasks list --json --assignee "$assignee" --folder "$folder" > "$tmpfile" \
      || { printf " failed\n" >&2; return 1; }
    printf " done\n" >&2

    local jq_filter='.[]'
    [[ -n "$release"  ]] && jq_filter+=" | select(.customFields[\"${release_field}\"] == \"${release}\")"
    [[ -n "$days_ago" ]] && jq_filter+=" | select(.updatedDate | fromdateiso8601 > (now - 86400 * ${days_ago}))"

    local header="  Assignee: ${assignee}  |  Release: ${release:-all}  |  Updated: last ${days_ago:-any} day(s)"

    local selected
    selected=$(
      jq -r "[${jq_filter}] | sort_by(.updatedDate) | reverse | .[] | [.id, .status, (.type // \"Task\"), (.updatedDate[:16] | gsub(\"T\"; \" \")), .title] | @tsv" "$tmpfile" \
      | awk -F'\t' '{printf "%s\t%-20s  %-14s  %-16s  %s\n", $1, substr($2,1,20), substr($3,1,14), $4, $5}' \
      | fzf --ansi --height 90% \
          --layout reverse \
          --delimiter $'\t' \
          --with-nth '2..' \
          --header "$header" \
          --preview-window 'down,75%,border-top,wrap' \
          --preview "
            jq -r --arg id {1} '
              .[] | select(.id == \$id) |
              \"\\u001b[1m\" + .title + \"\\u001b[0m\", \"\",
              \"\\u001b[2mStatus:     \\u001b[0m\" + .status,
              \"\\u001b[2mType:       \\u001b[0m\" + (.type // \"Task\"),
              \"\\u001b[2mImportance: \\u001b[0m\" + .importance,
              \"\\u001b[2mUpdated:    \\u001b[0m\" + (.updatedDate[:16] | gsub(\"T\"; \" \")),
              \"\\u001b[2mCreated:    \\u001b[0m\" + (.createdDate[:16] | gsub(\"T\"; \" \")),
              \"\\u001b[2mRequestor:  \\u001b[0m\" + (.customFields.Requestor // \"-\"),
              \"\\u001b[2mPriority:   \\u001b[0m\" + (.customFields.Priority // \"-\"),
              \"\\u001b[2mLink:       \\u001b[0m\\u001b[36m\" + .permalink + \"\\u001b[0m\",
              \"\", \"\\u001b[2m─────────────────\\u001b[0m\"
            ' ${tmpfile}
            jq -r --arg id {1} '.[] | select(.id == \$id) | .description // \"(none)\"' ${tmpfile} \
              | lynx -dump -nolist -stdin 2>/dev/null
            printf '\n\n\n\n\n\n\n\n\n\n'
            jq -C --arg id {1} '.[] | select(.id == \$id)' ${tmpfile}
          " \
          --bind 'shift-up:preview-up,shift-down:preview-down' \
      | cut -f1
    )

    [[ -z "$selected" ]] && return 0
    local permalink
    permalink=$(jq -r --arg id "$selected" '.[] | select(.id == $id) | .permalink' "$tmpfile")
    [[ -n "$permalink" ]] && open "$permalink"
  } always {
    rm -f "$tmpfile"
  }
}
