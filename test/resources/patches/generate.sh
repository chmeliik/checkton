#!/bin/bash
set -o errexit -o nounset -o pipefail

# cd to the repo root
cd "$(git rev-parse --show-toplevel)"

WORKSPACE_DIR=$(mktemp --dry-run --tmpdir "checkton-patch-gen.XXXXXX")

git worktree add -d "$WORKSPACE_DIR"
trap 'git worktree remove --force "$WORKSPACE_DIR"' EXIT

gen_patches() {
    local tektontask=test/resources/files-to-check/tektontask.yaml

    cat << EOF >> "$tektontask"

    - name: new-script
      image: foo:latest
      script: |
        if [[ violence = 'inherent in the system' ]]; then
          echo "Ah, now we see the violence inherent in the system!"
        fi
EOF

    git add "$tektontask"
    _commit_and_save_patch "Add a script with some issues"

    local cooltask=${tektontask%/*}/cooltask.yaml
    git mv "$tektontask" "$cooltask"
    _commit_and_save_patch "Rename tektontask to cooltask"

    git reset HEAD^
    git checkout -- "$tektontask"
    git add "$cooltask"
    _commit_and_save_patch "Copy tektontask to cooltask"

    sed -i 's/^From [0-9a-f]*/From deadbeef01deadbeef02deadbeef03deadbeef04/' \
        test/resources/patches/*.patch
}

_commit_and_save_patch() {
    local commit_args=(
        --author "Checkton Patcher <checkton-patcher@noreply.org>"
        --date "Thu, 20 Jun 2024 16:00:00 +0000"
    )
    git commit "${commit_args[@]}" -m "$1"
    git format-patch -1 -o test/resources/patches
}

(
    cd "$WORKSPACE_DIR"
    gen_patches
)

cp "$WORKSPACE_DIR/test/resources/patches"/*.patch test/resources/patches
