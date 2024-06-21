#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

BASE=${CHECKTON_DIFF_BASE:-$(git rev-parse main)}
HEAD=${CHECKTON_DIFF_HEAD:-$(git rev-parse HEAD)}

DIFF_ARGS=(--diff-filter=d)
if [[ "${CHECKTON_FIND_RENAMES:-}" != "false" ]]; then
    DIFF_ARGS+=("-M${CHECKTON_FIND_RENAMES:-}")
fi
if [[ "${CHECKTON_FIND_COPIES:-}" != "false" ]]; then
    DIFF_ARGS+=("-C${CHECKTON_FIND_COPIES:-}")
fi
if [[ "${CHECKTON_FIND_COPIES_HARDER:-}" == "true" ]]; then
    DIFF_ARGS+=(--find-copies-harder)
fi

DIFFERENTIAL=${CHECKTON_DIFFERENTIAL:-"true"}

WORKDIR=$(mktemp -d --tmpdir "checkton-workdir.XXXXXX")

cleanup() {
    rm -rf "$WORKDIR" || true
    git worktree list | awk '{ print $1 }' | while read -r worktree; do
        if [[ "$worktree" == "$WORKDIR"/* ]]; then
            git worktree remove "$worktree" 2>/dev/null || true
        fi
    done
}

trap cleanup EXIT

# {head_ref_filename => base_ref_filename or ""}
declare -A FILE_PAIRS=()

collect_file_pairs() {
    local filename
    while read -r filename; do
        FILE_PAIRS[$filename]=""
    done < <(_ls_files_to_check)

    echo "Files to check:" >&2
    if [[ ${#FILE_PAIRS[@]} -eq 0 ]]; then
        echo "  <none>" >&2
        return
    fi

    if [[ "$DIFFERENTIAL" == "false" ]]; then
        # print just the filenames at HEAD
        printf "  %s\n" "${!FILE_PAIRS[@]}" >&2
        return
    fi

    local line status old_name current_name
    while read -r line; do
        read -r status old_name current_name <<< "$line"

        if [[ -z "$current_name" ]]; then
            current_name=$old_name
        fi

        if [[ "${FILE_PAIRS[$current_name]+is_set}" != is_set ]]; then
            continue
        fi

        if _should_diff_file "$status"; then
            FILE_PAIRS[$current_name]=$old_name
        fi

        # print the full status of each file
        echo "  $line" >&2
    done < <(git diff --name-status "${DIFF_ARGS[@]}" "${BASE}...${HEAD}")
}

_ls_files_to_check() {
    if [[ "$DIFFERENTIAL" == "false" ]]; then
        git ls-tree -r --name-only "$HEAD"
    else
        git diff --name-only "${DIFF_ARGS[@]}" "${BASE}...${HEAD}"
    fi | _apply_include_exlude_patterns | sort -u
}

_apply_include_exlude_patterns() {
    local include_regex=${CHECKTON_INCLUDE_REGEX:-'\.ya?ml$'}
    local exclude_regex=${CHECKTON_EXCLUDE_REGEX:-}

    _nofail_grep -E "$include_regex" |
    if [[ -n "$exclude_regex" ]]; then _nofail_grep -v -E "$exclude_regex"; else cat; fi
}

_nofail_grep() {
    local rc=0
    grep "$@" || rc=$?
    [[ $rc -eq 1 ]] && rc=0
    return $rc
}

_should_diff_file() {
    local gitstatus=$1

    case "$gitstatus" in
        *A*)    false ;;  # the file didn't exist in the base ref
        *R*)    [[ "${CHECKTON_FIND_RENAMES:-}" != "false" ]] ;;
        *C*)    [[ "${CHECKTON_FIND_COPIES:-}" != "false" ]] ;;
        *)      true ;;
    esac
}

# NOTE: may change the PWD, best called in a subshell
at_ref() {
    local ref=$1
    shift

    if [[ "$ref" != "$(git rev-parse HEAD)" ]]; then
        local worktree=$WORKDIR/repo-${ref}
        # don't print unwanted fluff to stderr unless the command errors
        _with_deferred_stderr git worktree add -d "$worktree" "$ref" >/dev/null
        cd "$worktree"
        _with_deferred_stderr git checkout "$ref" >/dev/null
    fi
}

_with_deferred_stderr() {
    local errfile
    errfile=$(mktemp -p "$WORKDIR" err.XXXXXX)
    local rc=0
    "$@" 2> "$errfile" || rc=$?
    if [[ $rc -ne 0 ]]; then
        cat "$errfile" >&2
    fi
    return $rc
}

dupe_renamed_and_copied_files() {
    local current_name old_name
    for current_name in "${!FILE_PAIRS[@]}"; do
        old_name=${FILE_PAIRS[$current_name]}
        if [[ -n "$old_name" && "$old_name" != "$current_name" && ! -e "$current_name" ]]; then
            cp "$old_name" "$current_name"
        fi
    done
}

checkton() {
    "${SCRIPTDIR}/checkton.py" "$@"
}

csgrep_embed() {
    csgrep --mode=json --embed 1
}

main() {
    collect_file_pairs

    local old_files
    mapfile -t old_files < <(printf "%s\n" "${FILE_PAIRS[@]}" | sed '/^$/d')
    local new_files=("${!FILE_PAIRS[@]}")

    if [[ "${#new_files[@]}" -eq 0 ]]; then
        return
    fi

    local old_results=$WORKDIR/old.err
    local new_results=$WORKDIR/new.err

    if [[ ${#old_files[@]} -gt 0 ]]; then
        local all_files
        mapfile -t all_files < <(printf "%s\n" "${old_files[@]}" "${new_files[@]}" | sort -u)
        (
            at_ref "$BASE"
            dupe_renamed_and_copied_files
            checkton "${all_files[@]}" | csgrep_embed > "$old_results"
        )
    else
        touch "$old_results"
    fi

    (
        at_ref "$HEAD"
        checkton "${new_files[@]}" | csgrep_embed > "$new_results"
    )

    csdiff "$old_results" "$new_results"
}

main
