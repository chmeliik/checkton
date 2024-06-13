# Checkton

This action runs [ShellCheck][shellcheck] on scripts embedded in YAML files.
Primarily intended for use with Tekton files, but will work more or less generically
if your scripts start with shebang lines.

Similarly to the [Differential ShellCheck][differential-shellcheck] action
(a great source of inspiration for this one), Checkton reports new warnings
introduced in a PR and ignores existing warnings.

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
        uses: chmeliik/checkton@main
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

Report new issues introduced in a Pull Request, ignore existing issues. Set to
false to report all issues in all files.

* default: `true`

### `pull-request-base`

Hash of the latest commit in the base branch.

* default: `${{ github.event.pull_request.base.sha }}`

### `pull-request-head`

Hash of the latest commit in the Pull Request.

* default: `${{ github.event.pull_request.head.sha }}`

### `fail-on-findings`

Fail when ShellCheck reports some findings? (May wish to set this to false if
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

## Outputs

### `sarif`

Path to the generated SARIF report.

<!-- </automated> -->

[shellcheck]: https://www.shellcheck.net/wiki/Home
[differential-shellcheck]: https://github.com/redhat-plumbers-in-action/differential-shellcheck
