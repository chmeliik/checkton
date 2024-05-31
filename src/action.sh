#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

git config --global --add safe.directory "$PWD"
diff=$("$SCRIPTDIR"/differential-checkton.sh | csgrep)

if [[ -z "$diff" ]]; then
    echo "✅ No new shellcheck warnings, congrats! \\o/"
else
    echo "❌ PR introduces new shellcheck warnings! /o\\"
    csgrep --embed-context 4 <<< "$diff"
fi

# https://github.com/redhat-plumbers-in-action/differential-shellcheck/blob/5bfdb529b4cdf97e5ef3da1c06bab1b21aae83be/src/functions.sh#L341
uploadSARIF () {
    local sarif=$1
    local payload
    payload='{
        "commit_oid":"'"${HEAD}"'",
        "ref":"'"${GITHUB_REF//merge/head}"'",
        "analysis_key":"checkton",
        "sarif":"'"$(gzip -c <<< "$sarif" | base64 -w0)"'",
        "tool_names":["checkton"]
    }'

    local curl_args=(
        --silent
        --show-error
        --fail-with-body
        -X PUT
        -H "Authorization: token ${GITHUB_TOKEN}"
        -H "Accept: application/vnd.github.v3+json"
        -d "$payload"
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/code-scanning/analysis"
    )

    if curl "${curl_args[@]}"; then
        echo "✅ SARIF report was successfully uploaded to GitHub"
    else
        echo "❌ Failed to upload the SARIF report to GitHub"
    fi
}

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    shellcheck_version=$(shellcheck --version | awk '/version:/ { print $2 }')
    sarif=$(
        csgrep \
            --mode=sarif \
            --set-scan-prop="tool:ShellCheck" \
            --set-scan-prop="tool-version:${shellcheck_version}" \
            --set-scan-prop="tool-url:https://www.shellcheck.net/wiki/" \
            <<< "$diff"
    )
    uploadSARIF "$sarif"
elif [[ -n "$diff" ]]; then
    # If we cannot upload the SARIF data, failing here is the only way to notify user of warnings.
    # Otherwise, GitHub will do that automatically once the report is uploaded.
    exit 1
fi
