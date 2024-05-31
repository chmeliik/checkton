#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    git config --global --add safe.directory "$GITHUB_WORKSPACE"
fi
diff=$("$SCRIPTDIR"/differential-checkton.sh | csgrep)

if [[ -z "$diff" ]]; then
    echo "✅ No new shellcheck warnings, congrats! \\o/"
else
    echo "❌ PR introduces new shellcheck warnings! /o\\"
    csgrep --embed-context 4 <<< "$diff"
fi

shellcheck_version=$(shellcheck --version | awk '/version:/ { print $2 }')
csgrep \
    --mode=sarif \
    --set-scan-prop="tool:ShellCheck" \
    --set-scan-prop="tool-version:${shellcheck_version}" \
    --set-scan-prop="tool-url:https://www.shellcheck.net/wiki/" \
    <<< "$diff" \
    > .checkton.sarif

echo "sarif=.checkton.sarif" >> "${GITHUB_OUTPUT:-/dev/stdout}"

if [[ "${CHECKTON_FAIL_ON_FINDINGS:-}" == "true" ]] && [[ -n "$diff" ]]; then
    exit 1
fi
