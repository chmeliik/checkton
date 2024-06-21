# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

*Nothing yet.*

## [v0.1.0-test] - 2024-06-21

*Nothing yet.*

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
[v0.1.0-test]: https://github.com/chmeliik/checkton/compare/v0.1.0...v0.1.0-test
[unreleased]: https://github.com/chmeliik/checkton/compare/v0.1.0-test...HEAD
