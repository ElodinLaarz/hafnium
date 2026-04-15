#!/usr/bin/env python3
"""Fail when GDScript function signatures are missing type hints.

This checker complements `gdlint`, which does not currently provide a built-in
rule for enforcing typed function parameters and return values.

It supports a baseline file so the repository can enforce "no new violations"
without requiring a one-shot cleanup of all existing untyped signatures.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


FUNC_PATTERN = re.compile(
    r"^\s*(?:static\s+)?func\s+([^\(\s]+)\s*\(([^)]*)\)\s*(?:->\s*([^:]+))?:"
)


@dataclass(frozen=True)
class Violation:
    rel_path: str
    line_number: int
    function_name: str
    missing_kind: str

    @property
    def baseline_key(self) -> str:
        return f"{self.rel_path}|{self.function_name}|{self.missing_kind}"


def split_parameters(raw_params: str) -> list[str]:
    parts: list[str] = []
    current: list[str] = []
    depth = 0

    for char in raw_params:
        if char == "," and depth == 0:
            part = "".join(current).strip()
            if part:
                parts.append(part)
            current = []
            continue

        current.append(char)
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth = max(depth - 1, 0)

    part = "".join(current).strip()
    if part:
        parts.append(part)

    return parts


def normalize_targets(raw_targets: list[str], repo_root: Path) -> list[Path]:
    normalized: list[Path] = []

    for raw_target in raw_targets:
        candidate = Path(raw_target)
        if not candidate.is_absolute():
            candidate = (repo_root / candidate).resolve()
        normalized.append(candidate)

    return normalized


def iter_gd_files(targets: list[Path]) -> list[Path]:
    gd_files: list[Path] = []

    for target in targets:
        if target.is_dir():
            gd_files.extend(sorted(target.rglob("*.gd")))
        elif target.is_file() and target.suffix == ".gd":
            gd_files.append(target)

    return sorted(set(gd_files))


def collect_violations(gd_file: Path, repo_root: Path) -> list[Violation]:
    rel_path = gd_file.relative_to(repo_root).as_posix()
    violations: list[Violation] = []

    for line_number, line in enumerate(gd_file.read_text(encoding="utf-8").splitlines(), 1):
        match = FUNC_PATTERN.match(line)
        if match is None:
            continue

        function_name = match.group(1).strip()
        raw_params = match.group(2).strip()
        return_type = (match.group(3) or "").strip()

        for param in split_parameters(raw_params):
            if param.startswith("*"):
                continue

            signature_head = param.split("=", 1)[0].strip()
            if ":" not in signature_head:
                param_name = signature_head
                violations.append(
                    Violation(rel_path, line_number, function_name, f"param:{param_name}")
                )

        if not return_type:
            violations.append(Violation(rel_path, line_number, function_name, "return"))

    return violations


def load_baseline(baseline_path: Path | None) -> set[str]:
    if baseline_path is None or not baseline_path.is_file():
        return set()

    return {
        line.strip()
        for line in baseline_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "targets",
        nargs="+",
        help="Files or directories to scan. Relative paths are resolved from the repo root.",
    )
    parser.add_argument(
        "--baseline",
        default=".githooks/gdscript_type_hints_baseline.txt",
        help="Path to a baseline file of pre-existing violations.",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    baseline_path = (repo_root / args.baseline).resolve()
    baseline = load_baseline(baseline_path)

    targets = normalize_targets(args.targets, repo_root)
    gd_files = iter_gd_files(targets)

    unexpected: list[Violation] = []
    for gd_file in gd_files:
        for violation in collect_violations(gd_file, repo_root):
            if violation.baseline_key not in baseline:
                unexpected.append(violation)

    if not unexpected:
        print("[type-hints] OK")
        return 0

    print("[type-hints] Missing type hints detected:")
    for violation in unexpected:
        if violation.missing_kind == "return":
            detail = "missing return type"
        else:
            detail = "missing type for %s" % violation.missing_kind.split(":", 1)[1]
        print(
            "  %s:%d: `%s` %s"
            % (
                violation.rel_path,
                violation.line_number,
                violation.function_name,
                detail,
            )
        )

    return 1


if __name__ == "__main__":
    sys.exit(main())
