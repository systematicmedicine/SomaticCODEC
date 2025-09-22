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

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_somatic_variant_germline_contexts.py")

    # Inputs
    ms_pileup_vcf = Path(snakemake.input.ms_pileup_vcf)
    ex_somatic_vcf = Path(snakemake.input.ex_somatic_vcf)

    # Outputs
    germline_context_vcf = Path(snakemake.output.vcf)

    # --- Compress & index MS pileup and ex somatic VCFs ---
    with tempfile.TemporaryDirectory() as tmpdir:
        ms_intermediate_bgz = Path(tmpdir) / "ms_intermediate_bgz.vcf.gz"
        ex_intermediate_bgz = Path(tmpdir) / "ex_intermediate_bgz.vcf.gz"

        with open(ms_intermediate_bgz, "wb") as out_f, open(snakemake.log[0], "a") as log_file:
            subprocess.run(["bgzip", "-c", str(ms_pileup_vcf)], stdout=out_f, stderr=log_file, check=True)

        with open(snakemake.log[0], "a") as log_file:
            subprocess.run(["tabix", "-p", "vcf", str(ms_intermediate_bgz)], stderr=log_file, check=True)
        
        with open(ex_intermediate_bgz, "wb") as out_f, open(snakemake.log[0], "a") as log_file:
            subprocess.run(["bgzip", "-c", str(ex_somatic_vcf)], stdout=out_f, stderr=log_file, check=True)

        with open(snakemake.log[0], "a") as log_file:
            subprocess.run(["tabix", "-p", "vcf", str(ex_intermediate_bgz)], stderr=log_file, check=True)

        # --- Get germline records for positions where somatic variants were called ---
        germline_context_vcf.parent.mkdir(parents=True, exist_ok=True)
        with open(snakemake.log[0], "a") as log_file:
            subprocess.run(
                ["bcftools", "view",
                "-T", str(ex_intermediate_bgz),
                str(ms_intermediate_bgz),
                "-o", str(germline_context_vcf)],
                stdout=log_file,
                stderr=log_file,
                check=True
            )

    print(f"[INFO] Completed ex_somatic_variant_germline_contexts.py")

if __name__ == "__main__":
    main(snakemake)
