"""
Includes all rules within the rules/ subdirectories
"""

import os
import glob

# Get full paths to rule files
rule_files = glob.glob(os.path.join(workflow.basedir, "rules/**/*.smk"), recursive=True)

print(f"[INFO] Including {len(rule_files)-1} rule files from rules/")

for rule_file in rule_files:
    if os.path.basename(rule_file) != "include_all.smk":
        include: rule_file