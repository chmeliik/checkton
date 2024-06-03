#!/bin/bash
set -o errexit -o nounset -o pipefail

fmt() {
    jq -r '
        to_entries[]
        | (
            "### `\(.key)`\n\n"
            + if .value.required then "**\\[REQUIRED\\]**\n\n" else "" end
            + .value.description + "\n\n"
            + if .value.default != null then "* default: `\(.value.default)`\n" else "" end
        )
    ' | fold -w 80 -s | sed 's/ *$//'
}

inputs=$(yq < action.yaml '.inputs' -o json | fmt)
outputs=$(yq < action.yaml '.outputs' -o json | fmt)

new_readme=$(
    awk '{ print } /<automated>/ { exit }' README.md
    echo
    printf "## Inputs\n\n%s\n\n" "$inputs"
    printf "## Outputs\n\n%s\n\n" "$outputs"
    awk '/<\/automated>/,0' README.md
)

printf "%s\n" "$new_readme" > README.md
