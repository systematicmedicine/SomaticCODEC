"""
--- ms_extract_fastq_umis.py ---

Moves 12bp UMI from i7 index to the end of the read header. To be used with rule ms_extract_fastq_umis.

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import sys
import gzip

def main(snakemake):
    # Redirect stdout/stderr to log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ms_extract_fastq_umis.py")

    # Define inputs
    input_r1 = snakemake.input.r1
    input_r2 = snakemake.input.r2

    # Define outputs
    output_r1 = snakemake.output.r1
    output_r2 = snakemake.output.r2

    def extract_fastq_UMIs(in_file, out_file):
        with gzip.open(in_file, "rt") as fin, gzip.open(out_file, "wt") as fout:
            while True:
                header = fin.readline()
                if not header:
                    break
                seq = fin.readline()
                plus = fin.readline()
                qual = fin.readline()
                
                # Example header: 
                # @LH00144:391:233TTYLT3:8:1101:1240:1064 1:N:0:TTACCGACAAAAAAAAAAAA+CGTATTCG
                # Split header into two parts (before and after space)
                parts = header.strip().split()
                
                # Get last part of second half of header (indices and UMI)
                idx_info = parts[1]  # "1:N:0:TTACCGACAAAAAAAAAAAA+CGTATTCG"
                idx_parts = idx_info.split(":")
                last_part = idx_parts[-1]

                # Split into indices and UMI
                i7 = last_part[:8]
                umi = last_part[8:20]  # 12 bp UMI
                i5 = last_part[20+1:]   # after '+'

                # Rewrite header to append UMI at the end
                parts[1] = ":".join(idx_parts[:-1] + [f"{i7}+{i5}:{umi}"])
                fout.write(" ".join(parts) + "\n" + seq + plus + qual)

    extract_fastq_UMIs(input_r1, output_r1)
    extract_fastq_UMIs(input_r2, output_r2)

    print("[INFO] Completed ms_extract_fastq_umis.py")

if __name__ == "__main__":
    main(snakemake)
