#!/bin/bash
set -o errexit -o nounset -o pipefail

base_image=$(awk '/FROM/ { print $2 }' Dockerfile)

mapfile -t updated_rpms < <(
    podman run --rm "$base_image" microdnf list \
        ShellCheck \
        csdiff \
        git \
        python-unversioned-command |
    awk '
        /Available packages/ { flag = 1; next }
        flag { sub(/\..*/, "", $1); printf "%s-%s\n", $1, $2 }
    '
    # ^ "ShellCheck.x86_64 0.9.0-6.fc40 fedora" -> "ShellCheck-0.9.0-6.fc40"
)

updated_dockerfile=$(
    awk '/ShellCheck/ { exit } { print }' Dockerfile
    printf '        %s \\\n' "${updated_rpms[@]}"
    awk '/microdnf clean/,0' Dockerfile
)

printf "%s\n" "$updated_dockerfile" > Dockerfile
