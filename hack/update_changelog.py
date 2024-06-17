#!/usr/bin/env python
import argparse
import datetime
import itertools
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("-r", "--release-version", required=True)
    ap.add_argument("-R", "--repository", required=True)
    ap.add_argument("-p", "--prev-version")
    ap.add_argument("-f", "--changelog-file", type=Path, default=Path("CHANGELOG.md"))

    args = ap.parse_args()

    release_version: str = args.release_version
    prev_version: str = args.prev_version
    changelog_file: Path = args.changelog_file
    repository: str = args.repository

    def transform_line(line: str) -> list[str]:
        if line.startswith("## [Unreleased]"):
            return [
                line,
                "",
                "*Nothing yet.*",
                "",
                f"## [{release_version}] - {datetime.date.today().isoformat()}",
            ]
        if line.startswith(("[unreleased]: ", "[Unreleased]: ")):
            repo_url = f"https://github.com/{repository}"
            link = (
                f"{repo_url}/releases/tag/{release_version}"
                if not prev_version
                else f"{repo_url}/compare/{prev_version}...{release_version}"
            )
            return [
                f"[{release_version}]: {link}",
                f"[unreleased]: {repo_url}/compare/{release_version}...HEAD",
            ]
        return [line]

    lines = changelog_file.read_text().splitlines()
    if any(line.startswith(f"## [{release_version}]") for line in lines):
        ap.exit(status=0, message=f"{release_version} already released\n")

    transformed = itertools.chain.from_iterable(map(transform_line, lines))

    with changelog_file.open("w") as f:
        f.write("\n".join(transformed))
        f.write("\n")


if __name__ == "__main__":
    main()
