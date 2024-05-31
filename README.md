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

## Outputs

<!-- </automated> -->

[shellcheck]: https://www.shellcheck.net/wiki/Home
[differential-shellcheck]: https://github.com/redhat-plumbers-in-action/differential-shellcheck
