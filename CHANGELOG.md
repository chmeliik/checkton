# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Detection of `busybox sh` scripts

### Changed

- Update base image for GitHub action to Fedora 41
  - Which comes with [ShellCheck v0.10.0][shellcheck-v010], which adds support
    for `busybox sh`

[shellcheck-v010]: https://github.com/koalaman/shellcheck/blob/master/CHANGELOG.md#v0100---2024-03-07

## [v0.2.2] - 2024-07-29

### Fixed

- Run the formatter (`csgrep` or `sarif-fmt`) at the correct git ref
  - Before, Checkton would run the analysis at the specified commit but would
    then run the formatter at HEAD, potentially resulting in incorrect output.

## [v0.2.1] - 2024-07-22

### Fixed

- In v0.2.0, Checkton would always fail when there were no files to check /o\\
  - And also erroneously reported that there were ShellCheck warnings

## [v0.2.0] - 2024-07-19

### Added

- By default, Checkton now uses `sarif-fmt` to display violations
  - Note that `sarif-fmt` also outputs the wiki link for each violation :tada:
- A `display-style` option to allow switching back to `csgrep` to display violations

## [v0.1.2] - 2024-06-21

### Fixed

- Moving/copying a file into a directory that did not exist in the base ref would
  cause Checkton to fail when trying to copy the file

## [v0.1.1] - 2024-06-21

### Fixed

- The success/failure message did not make sense with `differential: false`, now
  it's more generic
- Introducing a ShellCheck violation into a file that already has a violation of
  the same type could confuse Checkton, making it report the old violation instead
  of the new one.

## [v0.1.0] - 2024-06-21

### Fixed

- A script nested inside another script (e.g. inside a heredoc string) no longer
  breaks the enclosing script

## [v0.1.0-alpha.2] - 2024-06-18

### Fixed

- The `.runs.image` syntax in action.yaml

## [v0.1.0-alpha.1] - 2024-06-18

### Added

- The initial implementation of Checkton :tada:
- `differential` param to enable non-differential mode (report existing issues too)
- `include-regex` and `exclude-regex` params to specify which file paths to check
- Pre-built container image so that the user's workflow doesn't have to build the
  image

[v0.1.0-alpha.1]: https://github.com/chmeliik/checkton/releases/tag/v0.1.0-alpha.1
[v0.1.0-alpha.2]: https://github.com/chmeliik/checkton/compare/v0.1.0-alpha.1...v0.1.0-alpha.2
[v0.1.0]: https://github.com/chmeliik/checkton/compare/v0.1.0-alpha.2...v0.1.0
[v0.1.1]: https://github.com/chmeliik/checkton/compare/v0.1.0...v0.1.1
[v0.1.2]: https://github.com/chmeliik/checkton/compare/v0.1.1...v0.1.2
[v0.2.0]: https://github.com/chmeliik/checkton/compare/v0.1.2...v0.2.0
[v0.2.1]: https://github.com/chmeliik/checkton/compare/v0.2.0...v0.2.1
[v0.2.2]: https://github.com/chmeliik/checkton/compare/v0.2.1...v0.2.2
[unreleased]: https://github.com/chmeliik/checkton/compare/v0.2.2...HEAD
