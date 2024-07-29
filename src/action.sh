#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    git config --global --add safe.directory "$GITHUB_WORKSPACE"
fi

checkout() {
    if ! stderr=$(git checkout "$@" 2>&1 1>/dev/null); then
        printf "%s\n" "$stderr" >&2
        return 1
    fi
}

if [[ -n "${CHECKTON_DIFF_HEAD:-}" ]]; then
    current_ref=$(git rev-parse HEAD)
    checkout "$CHECKTON_DIFF_HEAD"
    trap 'checkout $current_ref' EXIT
fi

"$SCRIPTDIR"/differential-checkton.sh > .checkton.sarif

exitcode=0

if jq -e '[.runs[].results[]] | length == 0' < .checkton.sarif >/dev/null; then
    echo "✅ No ShellCheck warnings, congrats! \\o/"
else
    echo "❌ Found ShellCheck warnings! /o\\"

    if [[ "${GITHUB_ACTIONS:-false}" == true ]]; then
        # csgrep colored output doesn't look very good in GH actions, use colors only for sarif-fmt
        sarif_fmt_color=always
    else
        sarif_fmt_color=auto
    fi

    case "${CHECKTON_DISPLAY_STYLE:-sarif-fmt}" in
        csgrep)
            csgrep --embed 4 < .checkton.sarif ;;
        sarif-fmt)
            sarif-fmt --color="$sarif_fmt_color" < .checkton.sarif ;;
        *)
            echo "Unknown display style: $CHECKTON_DISPLAY_STYLE" >&2
            exit 1
            ;;
    esac

    if [[ "${CHECKTON_FAIL_ON_FINDINGS:-}" == "true" ]]; then
        exitcode=1
    fi
fi

echo "sarif=.checkton.sarif" >> "${GITHUB_OUTPUT:-/dev/stdout}"
exit $exitcode
