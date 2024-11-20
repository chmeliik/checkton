# Checkton

This action runs [ShellCheck][shellcheck] on scripts embedded in YAML files.
Primarily intended for use with Tekton files, but will work more or less generically
if your scripts start with shebang lines.

Similarly to the [Differential ShellCheck][differential-shellcheck] action
(a great source of inspiration for this one), Checkton reports new warnings
introduced in a PR and ignores existing warnings.

* [Example usage](#example-usage)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [Development](#development)

## Example usage

```yaml
name: Checkton
on:
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          # Differential Checkton requires full git history
          fetch-depth: 0

      - name: Run Checkton
        id: checkton
        uses: chmeliik/checkton@v0.3.1
        with:
          # Let there be green. GitHub's code scanning will do the reporting.
          fail-on-findings: false

      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: ${{ steps.checkton.outputs.sarif }}
          # Avoid clashing with ShellCheck
          category: checkton
```

<!-- <automated> -->

## Inputs

### `differential`

Report new violations introduced in a Pull Request, ignore existing violations.
Set to false to report all violations in all files.

* default: `true`

### `include-regex`

Files paths to include (regex pattern).

* default: `\.ya?ml$`

### `exclude-regex`

Files paths to exclude (regex pattern).

* default: `""`

### `pull-request-base`

Hash of the latest commit in the base branch.

* default: `${{ github.event.pull_request.base.sha }}`

### `pull-request-head`

Hash of the latest commit in the Pull Request.

* default: `${{ github.event.pull_request.head.sha }}`

### `fail-on-findings`

Fail when ShellCheck reports some violations? (May wish to set this to false if
you're going to upload the SARIF report anyway. GitHub takes care of the
reporting.)

* default: `true`

### `find-renames`

Similarity threshold to detect renamed files (see the git-diff manpage). Set to
false to disable finding renames.

* default: `50%`

### `find-copies`

Similarity threshold to detect copied files (see the git-diff manpage). Set to
false to disable finding copies.

* default: `50%`

### `find-copies-harder`

Inspect unmodified files as candidates for the source of copy. This is a very
expensive operation for large projects, so use it with caution. (See the
git-diff manpage).

* default: `false`

### `display-style`

Display violations in the specified style. Valid values: csgrep, sarif-fmt

* default: `sarif-fmt`

## Outputs

### `sarif`

Path to the generated SARIF report.

<!-- </automated> -->

## Development

### Changelog

For every change relevant to users, add an entry into the Unreleased section in
[CHANGELOG.md](./CHANGELOG.md).

### Releases

Use the [Prepare Release](.github/workflows/prepare-release.yaml) workflow (from
the Actions tab in this repo) to prepare a release. When starting the workflow, select
the version number for the next release. Consult the changelog to figure out whether
to bump the major, minor or patch number.

The workflow will build the Checkton container image, tag it with the specified
version and test it. If the tests pass, the workflow will update the image ref in
action.yaml, update the changelog and submit a PR with the changes.

After merging the PR, tag the release commit. (Don't forget to pull the latest changes
from main, or you may tag an older commit). The [Release](.github/workflows/release.yaml)
workflow will automatically create a GitHub release for the tag.

TLDR:

* Run the Prepare Release workflow, choosing e.g. `v0.2.0` as the version
* Merge the PR submitted by the workflow
* Pull main
* Tag the release commit with `v0.2.0`
* Push the tag

### Tests

Checkton uses [bats] for testing. Per the bats tutorial, this repo includes bats
as a submodule. Fetch/update the required submodules with:

```bash
git submodule update --init
```

Run tests:

```bash
make test
```

The tests run Checkton (basic or differential) on a set of files and compare the
actual output with the expected output. They also know how to auto-generate the
expected data. When you add a new test, or when you make some changes that require
changing the expected data, run:

```bash
make generate-expected-test-output
```

When you change test inputs (the files that Checkton scans during the tests), the
differential tests may give errors about patches failing to apply. Fix with:

```bash
make generate-test-patches
```

[shellcheck]: https://www.shellcheck.net/wiki/Home
[differential-shellcheck]: https://github.com/redhat-plumbers-in-action/differential-shellcheck
[bats]: https://bats-core.readthedocs.io/en/stable/
