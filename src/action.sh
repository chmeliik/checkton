#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    git config --global --add safe.directory "$GITHUB_WORKSPACE"
fi

"$SCRIPTDIR"/differential-checkton.sh > .checkton.sarif

exitcode=0

if jq -e '[.runs[].results[]] | length == 0' < .checkton.sarif >/dev/null; then
    echo "✅ No ShellCheck warnings, congrats! \\o/"
else
    echo "❌ Found ShellCheck warnings! /o\\"
    csgrep --embed-context 4 < .checkton.sarif

    if [[ "${CHECKTON_FAIL_ON_FINDINGS:-}" == "true" ]]; then
        exitcode=1
    fi
fi

echo "sarif=.checkton.sarif" >> "${GITHUB_OUTPUT:-/dev/stdout}"
exit $exitcode
