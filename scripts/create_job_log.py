"""
--- create_job_log.py ---

Generates a csv with job metadata from the Snakemake log

To be used with the rule create_job_log

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import re
import csv
import sys
from datetime import datetime

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting create_job_log.py")

    log_file = snakemake.input.log
    csv_file = snakemake.output.csv

    # Regex patterns
    start_pattern = re.compile(
        r"\[(.*?)\]\s*rule\s+(\S+):.*?jobid:\s*(\d+)", re.DOTALL)
    finish_pattern = re.compile(r"\[(.*?)\]\s*Finished job (\d+)")

    def parse_dt(dt_str):
        match = re.search(
            r"([A-Za-z]{3} [A-Za-z]{3} \d{2} \d{2}:\d{2}:\d{2} \d{4})", dt_str)
        if not match:
            raise ValueError(f"Cannot parse timestamp from: {dt_str}")
        timestamp_str = match.group(1)
        return datetime.strptime(timestamp_str, "%a %b %d %H:%M:%S %Y")

    # Store data as jobid → info dict
    jobs = {}

    with open(log_file, 'r') as f:
        text = f.read()

    # Find all starts
    for match in start_pattern.finditer(text):
        timestamp_str, rule, jobid = match.groups()
        
        jobs[jobid] = {
            'jobid': jobid,
            'rule': rule,
            'start_time': parse_dt(timestamp_str),
            'finish_time': None
        }

    # Find all finishes
    for match in finish_pattern.finditer(text):
        timestamp_str, jobid = match.groups()
        if jobid in jobs:
            finish_dt = parse_dt(timestamp_str)
            jobs[jobid]['finish_time'] = finish_dt
            start_dt = jobs[jobid]['start_time']

    # Write to CSV
    with open(csv_file, 'w', newline='') as f:
        writer = csv.DictWriter(
            f, fieldnames=['jobid', 'rule', 'start_time', 'finish_time'])
        writer.writeheader()
        for job in jobs.values():

            if job['rule'] == "create_job_log":
                continue

            writer.writerow({
                'jobid': job['jobid'],
                'rule': job['rule'],
                'start_time': job['start_time'].strftime("%Y-%m-%d %H:%M:%S") if job['start_time'] else '',
                'finish_time': job['finish_time'].strftime("%Y-%m-%d %H:%M:%S") if job['finish_time'] else ''
            })

    print("[INFO] Completed create_job_log.py")

if __name__ == "__main__":
    main(snakemake)
