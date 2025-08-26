"""
--- ex_percent_eligible_N_bases.py

Calculates the percentage of N bases in bases eligible for variant calling (>0x duplex depth, unmasked, QUAL > min_base_quality)
for both pre- and post-consensus BAMs.

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import sys
import subprocess
import json

def main(snakemake):
    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting percent_eligible_N_bases.py")

    # Inputs
    bam_pre_consensus = snakemake.input.pre_dsc_bam
    bam_post_consensus = snakemake.input.post_dsc_bam
    include_bed = snakemake.input.include_bed
    sample = snakemake.params.sample

    # Output
    json_out_path = snakemake.output.json
    min_base_quality_pre_dsc = snakemake.params.min_base_quality_pre_dsc
    min_base_quality_post_dsc = snakemake.params.min_base_quality_post_dsc

    def count_Ns(bam_path, include_bed, min_base_quality):
        """
        Count N bases and total bases in a BAM within BED regions and above min base quality
        """
        total_bases = 0
        n_bases = 0
        cmd = [
            "samtools", "mpileup",
            "-Q", str(min_base_quality),
            "-l", include_bed,
            bam_path
        ]
        with open(snakemake.log[0], "a") as log_file:
            proc = subprocess.Popen(cmd,
                                    stdout=subprocess.PIPE,
                                    stderr=log_file,
                                    text=True)
            for line in proc.stdout:
                fields = line.strip().split()
                if len(fields) < 6:
                    continue
                depth = int(fields[3])
                read_bases = fields[4].upper()
                if depth > 0:
                    total_bases += depth
                    n_bases += read_bases.count("N")
            proc.stdout.close()
            proc.wait()

        percent_N = round((n_bases / total_bases * 100) if total_bases else 0, 2)
        return total_bases, n_bases, percent_N

    # Count Ns pre-consensus
    total_pre, n_pre, percent_N_pre = count_Ns(bam_pre_consensus, include_bed, min_base_quality_pre_dsc)

    # Count Ns post-consensus
    total_post, n_post, percent_N_post = count_Ns(bam_post_consensus, include_bed, min_base_quality_post_dsc)

    # Write output JSON
    output_data = {
        "sample": sample,
        "description": (
            "Summary of N bases in bases eligible for variant calling, pre- and post-duplex strand consensus.",
            "Definitions:",
            "pre_consensus_total_bases: Number of eligible bases before ex_call_dsc.",
            "pre_consensus_N_bases: Number of eligible N bases before ex_call_dsc.",
            "pre_consensus_percent_N: Percentage of eligible N bases before ex_call_dsc.",
            "post_consensus_total_bases: Number of eligible bases after ex_call_dsc.",
            "post_consensus_N_bases: Number of eligible N bases after ex_call_dsc.",
            "post_consensus_percent_N: Percentage of eligible N bases after ex_call_dsc."
        ),
        "pre_consensus_total_bases": total_pre,
        "pre_consensus_N_bases": n_pre,
        "pre_consensus_percent_N": percent_N_pre,
        "post_consensus_total_bases": total_post,
        "post_consensus_N_bases": n_post,
        "post_consensus_percent_N": percent_N_post
    }

    with open(json_out_path, "w") as f:
        json.dump(output_data, f, indent=4)

    print(f"[INFO] Completed percent_eligible_N_bases.py")


if __name__ == "__main__":
    main(snakemake)
