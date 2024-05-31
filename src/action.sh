#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

git config --global --add safe.directory "$PWD"
"$SCRIPTDIR"/differential-checkton.sh | csgrep --embed-context 4
