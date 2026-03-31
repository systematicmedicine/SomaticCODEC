#!/usr/bin/env python3
"""
--- create_runtime_config.py ---

Create a merged runtime config from an environment and a profile.

The merged config is written to:
    tmp/runtime_config/merged_config.yaml

Authors:
    - Cameron Fraser
"""

# ------------------------------------------------------------------------------------------
# Imports
# ------------------------------------------------------------------------------------------
import argparse
import sys
from pathlib import Path
import yaml

# ------------------------------------------------------------------------------------------
# Bootstrap helpers
# ------------------------------------------------------------------------------------------
def find_project_root(start: Path) -> Path:
    start = start.resolve()
    for p in [start, *start.parents]:
        if (
            (p / "profiles").is_dir()
            and (p / "environments").is_dir()
            and (p / "helpers").is_dir()
            and (p / "rule_scripts").is_dir()
            and (p / "Snakefile").is_file()
        ):
            return p
    raise RuntimeError(
        "Could not find repo root (profiles/, environments/, helpers/, rule_scripts/, Snakefile)."
    )

PROJECT_ROOT = find_project_root(Path(__file__))
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from helpers.config_helpers import build_config


# ------------------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a merged runtime config from an environment and a profile."
    )
    parser.add_argument(
        "--environment",
        required=True,
        help="Name of the environment directory under environments/.",
    )
    parser.add_argument(
        "--profile",
        required=True,
        help="Name of the profile directory under profiles/.",
    )
    return parser.parse_args()


# ------------------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------------------
def main() -> int:
    args = parse_args()

    output_dir = PROJECT_ROOT / "tmp" / "runtime_config"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "merged_config.yaml"

    config_data = build_config(args.environment, args.profile)

    with output_path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(config_data, f, sort_keys=False)

    print(f"[INFO] Environment: {args.environment}")
    print(f"[INFO] Profile: {args.profile}")
    print(f"[INFO] Wrote merged config to: {output_path}")

    return 0

if __name__ == "__main__":
    sys.exit(main())