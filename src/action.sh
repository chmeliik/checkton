#!/bin/bash
set -o errexit -o nounset -o pipefail

SCRIPTDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

"$SCRIPTDIR"/differential-checkton.sh | csgrep --embed-context 4
