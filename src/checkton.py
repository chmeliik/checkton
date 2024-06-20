#!/usr/bin/env python
from __future__ import annotations

import argparse
import contextlib
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Literal, NamedTuple, TypedDict, assert_type


class InlineScript(NamedTuple):
    lines: list[str]
    line_offset: int
    column_offset: int

    def gen_shellcheckable_file(self) -> str:
        left_aligned_lines = (line[self.column_offset :] for line in self.lines)
        return "\n".join(left_aligned_lines) + "\n"


def list_shell_scripts(yamlfile: Path) -> list[InlineScript]:
    scripts: list[InlineScript] = []
    shell_indent = None
    prev_nonempty_line = None

    def is_shell(line: str, prev_line: str | None) -> Literal["explicit", "implicit"] | None:
        # matches e.g. 'script:', 'script: |-' etc.
        script_attr = re.compile(r"\s*script:(\s+[>|][-+]?)?\s*$")
        shebang = re.compile(r"^\s*#!(?:/usr)?(?:/local)?/bin/(?:env )?(\S+)")
        known_interpreters = ("sh", "ash", "bash", "dash", "ksh", "bats")

        if match := shebang.match(line):
            return "explicit" if match.group(1) in known_interpreters else None
        elif prev_line and script_attr.match(prev_line):
            return "implicit"
        else:
            return None

    with yamlfile.open() as f:
        for i, line in enumerate(map(str.rstrip, f)):
            curr_indent = len(line) - len(line.lstrip())

            if shell_indent is not None and (not line or curr_indent >= shell_indent):
                scripts[-1].lines.append(line)
            elif is_sh := is_shell(line, prev_nonempty_line):
                shell_indent = curr_indent
                if is_sh == "explicit":
                    initial_script_lines = [line]
                    line_offset = i
                else:
                    indent = " " * curr_indent
                    # https://tekton.dev/docs/pipelines/tasks/#running-scripts-within-steps
                    initial_script_lines = [f"{indent}#!/bin/sh", f"{indent}set -e", line]
                    line_offset = i - 2  # we're injecting two lines that weren't there

                scripts.append(
                    InlineScript(initial_script_lines, line_offset, column_offset=curr_indent)
                )
            else:
                shell_indent = None

            if line:
                prev_nonempty_line = line

    return scripts


class ShellCheckJSON(TypedDict):
    comments: list[ShellCheckComment]


class ShellCheckComment(TypedDict):
    file: str
    line: int
    endLine: int
    column: int
    endColumn: int
    level: str
    code: int
    message: str
    fix: ShellCheckFix | None


class ShellCheckFix(TypedDict):
    replacements: list[ShellCheckReplacement]


class ShellCheckReplacement(TypedDict):
    line: int
    endLine: int
    column: int
    endColumn: int
    precedence: int
    insertionPoint: str
    replacement: str


def update_shellcheck_json(
    shellcheck_json: ShellCheckJSON,
    scriptdir: ScriptDir,
) -> None:
    for item in shellcheck_json["comments"]:
        filepath = Path(item["file"])
        script = scriptdir.get_inline_script(filepath)

        item["file"] = scriptdir.get_original_path(filepath).as_posix()
        for obj in (item, *(fix["replacements"] if (fix := item["fix"]) else [])):
            assert_type(obj, ShellCheckComment | ShellCheckReplacement)
            for k in "line", "endLine":
                obj[k] += script.line_offset
            for k in "column", "endColumn":
                obj[k] += script.column_offset


class ScriptDir:
    def __init__(self, scripts_by_file: dict[Path, list[InlineScript]], scriptdir: Path) -> None:
        self._scripts_by_file = scripts_by_file
        self._scriptdir = scriptdir

    def write(self) -> list[Path]:
        script_files = []

        for yamfile, scripts in self._scripts_by_file.items():
            scriptdir_for_file = self._scriptdir / yamfile
            if scripts:
                scriptdir_for_file.mkdir(parents=True, exist_ok=True)

            for i, script in enumerate(scripts):
                script_files.append(scriptdir_for_file / f"{i}.sh")
                script_files[-1].write_text(script.gen_shellcheckable_file())

        return script_files

    def get_original_path(self, scriptfile: Path) -> Path:
        return scriptfile.parent.relative_to(self._scriptdir)

    def get_inline_script(self, scriptfile: Path) -> InlineScript:
        original_path = self.get_original_path(scriptfile)
        return self._scripts_by_file[original_path][int(scriptfile.stem)]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--scriptdir", type=Path)
    args = ap.parse_args()

    with contextlib.ExitStack() as context:
        _main(args, context)


def _main(args: argparse.Namespace, context: contextlib.ExitStack) -> None:
    files: list[Path] = args.files
    scriptdir_path: Path | None = args.scriptdir

    if not scriptdir_path:
        tmpdir = tempfile.TemporaryDirectory(prefix="checkton-")
        scriptdir_path = Path(context.enter_context(tmpdir))

    scriptdir = ScriptDir(
        scripts_by_file={
            yamlfile: list_shell_scripts(yamlfile) for yamlfile in filter(Path.is_file, files)
        },
        scriptdir=scriptdir_path,
    )
    script_files = scriptdir.write()
    if not script_files:
        return

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

    shellcheck_json: ShellCheckJSON = json.loads(proc.stdout)
    update_shellcheck_json(shellcheck_json, scriptdir)

    print(json.dumps(shellcheck_json, separators=(",", ":")))


if __name__ == "__main__":
    main()
