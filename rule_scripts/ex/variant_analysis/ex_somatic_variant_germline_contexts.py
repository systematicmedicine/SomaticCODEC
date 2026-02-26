#!/usr/bin/env python3
"""
--- ex_somatic_variant_germline_contexts.py

Obtains the germline contexts for positions where somatic variants were called

Designed to be used exclusively with the rule "ex_somatic_variant_germline_contexts"

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

from pathlib import Path
import subprocess
import sys
import tempfile
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_somatic_variant_germline_contexts.py")

    # Inputs
    ms_pileup_bcf = Path(args.ms_pileup_bcf)
    ex_somatic_vcf = Path(args.ex_somatic_vcf)
    threads = args.threads

    # Outputs
    germline_context_vcf = Path(args.contexts_vcf)

    # --- Compress & index MS pileup and ex somatic VCFs ---
    with tempfile.TemporaryDirectory() as tmpdir:
        ms_intermediate_vcf = Path(tmpdir) / "ms_intermediate.vcf" 
        ms_intermediate_bgz = Path(tmpdir) / "ms_intermediate_bgz.vcf.gz"
        ex_intermediate_bgz = Path(tmpdir) / "ex_intermediate_bgz.vcf.gz"

        with open(ms_intermediate_vcf, "wb") as out_f, open(args.log, "a") as log_file:
            subprocess.run(["bcftools", "view", "--threads", str(threads), "-Ov", str(ms_pileup_bcf)], 
                           stdout=out_f, stderr=log_file, check=True)

        with open(ms_intermediate_bgz, "wb") as out_f, open(args.log, "a") as log_file:
            subprocess.run(["bgzip", "-@", str(threads), "-c", str(ms_intermediate_vcf)], stdout=out_f, stderr=log_file, check=True)

        with open(args.log, "a") as log_file:
            subprocess.run(["tabix", "--threads", str(threads), "-p", "vcf", str(ms_intermediate_bgz)], stderr=log_file, check=True)
        
        with open(ex_intermediate_bgz, "wb") as out_f, open(args.log, "a") as log_file:
            subprocess.run(["bgzip", "-c", "-@", str(threads), str(ex_somatic_vcf)], stdout=out_f, stderr=log_file, check=True)

        with open(args.log, "a") as log_file:
            subprocess.run(["tabix", "--threads", str(threads), "-p", "vcf", str(ex_intermediate_bgz)], stderr=log_file, check=True)

        # --- Get germline records for positions where somatic variants were called ---
        germline_context_vcf.parent.mkdir(parents=True, exist_ok=True)
        with open(args.log, "a") as log_file:
            subprocess.run(
                ["bcftools", "view",
                "--threads", str(threads),
                "-T", str(ex_intermediate_bgz),
                str(ms_intermediate_bgz),
                "-o", str(germline_context_vcf)],
                stdout=log_file,
                stderr=log_file,
                check=True
            )

    print(f"[INFO] Completed ex_somatic_variant_germline_contexts.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ms_pileup_bcf", required=True)
    parser.add_argument("--ex_somatic_vcf", required=True)
    parser.add_argument("--contexts_vcf", required=True)
    parser.add_argument("--threads", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
