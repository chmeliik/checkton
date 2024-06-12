#!/bin/bash
set -o errexit -o nounset -o pipefail

# cd to the repo root
cd "$(git rev-parse --show-toplevel)"

WORKSPACE_DIR=$(mktemp --dry-run --tmpdir "checkton-patch-gen.XXXXXX")

git worktree add -d "$WORKSPACE_DIR"
trap 'git worktree remove --force "$WORKSPACE_DIR"' EXIT

gen_patches() {
    local tektontask=test/resources/tektontask/tektontask.yaml

    cat << EOF >> "$tektontask"

    - name: new-script
      image: foo:latest
      script: |
        if [[ violence = 'inherent in the system' ]]; then
          echo "Ah, now we see the violence inherent in the system!"
        fi
EOF

    commit_args=(--author "Checkton Patcher <checkton-patcher@noreply.org>")

    git add "$tektontask"
    git commit "${commit_args[@]}" -m "Add a script with some issues"
    git format-patch -1 -o test/resources/patches

    local cooltask=${tektontask%/*}/cooltask.yaml
    git mv "$tektontask" "$cooltask"
    git commit "${commit_args[@]}" -m "Rename tektontask to cooltask"
    git format-patch -1 -o test/resources/patches

    git reset HEAD^
    git checkout -- "$tektontask"
    git add "$cooltask"
    git commit "${commit_args[@]}" -m "Copy tektontask to cooltask"
    git format-patch -1 -o test/resources/patches
}

(
    cd "$WORKSPACE_DIR"
    gen_patches
)

cp "$WORKSPACE_DIR/test/resources/patches"/*.patch test/resources/patches
