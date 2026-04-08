"""
--- clean_workspace.py ---

Deletes all files from metrics, results, logs, tmp and .snakemake directories.

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import shutil
import os

def clean_workspace(project_root):
    for folder in ["metrics", "results", "tmp", "logs", ".snakemake"]:
        root = project_root / folder
        if not root.exists():
            continue
        # Delete all files except .gitkeep
        for file in root.rglob("*"):
            if file.is_file() and file.name != ".gitkeep":
                try:
                    file.unlink()
                except FileNotFoundError:
                    pass
        # Remove directories that do not contain .gitkeep
        for dir_path in sorted(root.rglob("*"), key=lambda p: len(p.parts), reverse=True):
            if dir_path.is_dir():
                if not any(f.name == ".gitkeep" for f in dir_path.iterdir()):
                    try:
                        shutil.rmtree(dir_path)
                    except FileNotFoundError:
                        pass

    # Delete .pytest_cache and __pycache__ in all directories
    for pattern in (".pytest_cache", "__pycache__"):
        for cache_dir in project_root.rglob(pattern):
            shutil.rmtree(cache_dir)

    # Replace filled sample sheets with templates
    experiment_dir = project_root / "experiment"
    for file in os.listdir(experiment_dir):
        file_path = experiment_dir / file

        with open(file_path, "r", encoding="utf-8") as f:
            header = f.readline()

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(header)
