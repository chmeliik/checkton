#!/usr/bin/env python
import argparse
import contextlib
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Literal, NamedTuple


class InlineScript(NamedTuple):
    lineno: int
    lines: list[str]

    def gen_shellcheckable_file(self) -> str:
        shebang, *rest = self.lines
        lines = [shebang.lstrip()]
        lines.extend("" for _ in range(self.lineno - 1))
        lines.extend(rest)
        return "\n".join(lines) + "\n"


def list_shell_scripts(yamlfile: Path) -> list[InlineScript]:
    scripts: list[InlineScript] = []
    shell_indent = None
    prev_nonempty_line = None

    def is_shell(line: str, prev_line: str | None) -> Literal["explicit", "implicit"] | None:
        shebang = re.compile(r"^\s*#!(?:/usr)?(?:/local)?/bin/(?:env )?(\S+)")
        known_interpreters = ("sh", "ash", "bash", "dash", "ksh", "bats")

        if match := shebang.match(line):
            return "explicit" if match.group(1) in known_interpreters else None
        elif prev_line and prev_line.lstrip().startswith("script:"):
            return "implicit"
        else:
            return None

    with yamlfile.open() as f:
        for i, line in enumerate(map(str.rstrip, f)):
            curr_indent = len(line) - len(line.lstrip())

            if is_sh := is_shell(line, prev_nonempty_line):
                shell_indent = curr_indent
                if is_sh == "explicit":
                    initial_script_lines = [line]
                    lineno = i + 1
                else:
                    # https://tekton.dev/docs/pipelines/tasks/#running-scripts-within-steps
                    initial_script_lines = ["#!/bin/sh", f"{' ' * shell_indent}set -e", line]
                    lineno = i - 1  # we're injecting two lines that weren't there
                scripts.append(InlineScript(lineno, initial_script_lines))
            elif shell_indent is not None and (not line or curr_indent >= shell_indent):
                scripts[-1].lines.append(line)
            else:
                shell_indent = None

            if line:
                prev_nonempty_line = line

    return scripts


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--scriptdir", type=Path)
    args = ap.parse_args()

    with contextlib.ExitStack() as context:
        _main(args, context)


def _main(args: argparse.Namespace, context: contextlib.ExitStack) -> None:
    files: list[Path] = args.files
    scriptdir: Path | None = args.scriptdir

    if not scriptdir:
        tmpdir = tempfile.TemporaryDirectory(prefix="checkton-")
        scriptdir = Path(context.enter_context(tmpdir))

    script_files = []

    for yamfile in filter(Path.is_file, files):
        scripts = list_shell_scripts(yamfile)
        scriptdir_for_file = scriptdir / yamfile
        if scripts:
            scriptdir_for_file.mkdir(parents=True, exist_ok=True)

        for i, script in enumerate(scripts):
            script_files.append(scriptdir_for_file / f"{i}.sh")
            script_files[-1].write_text(script.gen_shellcheckable_file())

    shellcheck = shutil.which("shellcheck")
    if not shellcheck:
        exit("missing command: shellcheck")

    proc = subprocess.run([shellcheck, "-f", "json1", *script_files], stdout=subprocess.PIPE)
    # 0: All files successfully scanned with no issues.
    # 1: All files successfully scanned with some issues.
    # 2: Some files could not be processed (e.g.  file not found).
    # 3: ShellCheck was invoked with bad syntax (e.g.  unknown flag).
    # 4: ShellCheck was invoked with bad options (e.g.  unknown formatter).
    if not 0 <= proc.returncode <= 2:
        exit(f"shellcheck exited with: {proc.returncode}")

    shellcheck_json = json.loads(proc.stdout)

    for item in shellcheck_json["comments"]:
        filepath = Path(item["file"])
        item["file"] = filepath.parent.relative_to(scriptdir).as_posix()

    print(json.dumps(shellcheck_json, separators=(",", ":")))


if __name__ == "__main__":
    main()
