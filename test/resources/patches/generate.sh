#!/bin/bash
set -o errexit -o nounset -o pipefail

# cd to the repo root
cd "$(git rev-parse --show-toplevel)"

WORKSPACE_DIR=$(mktemp --dry-run --tmpdir "checkton-patch-gen.XXXXXX")

git worktree add -d "$WORKSPACE_DIR"
trap 'git worktree remove --force "$WORKSPACE_DIR"' EXIT

gen_patches() {
    local tektontask_dir=test/resources/files-to-check
    local tektontask=$tektontask_dir/tektontask.yaml

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
    local add_script_ref
    add_script_ref=$(git rev-parse HEAD)

    local cooltask=${tektontask_dir}/cooltask.yaml
    git mv "$tektontask" "$cooltask"
    _commit_and_save_patch "Rename tektontask to cooltask"

    local cooltask2=${tektontask_dir}/subdir/cooltask.yaml
    git reset HEAD^
    git checkout -- "$tektontask"
    mkdir -p "$tektontask_dir/subdir"
    cp "$tektontask" "$cooltask2"
    git add "$cooltask2"
    _commit_and_save_patch "Copy tektontask to cooltask"

    git revert --no-edit "$add_script_ref"
    echo "        echo \$HI" >> "$tektontask"
    git add "$tektontask"
    _commit_and_save_patch "Add another unquoted variable"

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
