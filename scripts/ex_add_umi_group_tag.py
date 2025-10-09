"""
--- ex_add_umi_group_tag.py ---

Takes the output of umi_tools group and makes the following modifications to the BAM tags:
    - Adds unique MI:Z tag to each read pair

To be used exclusively within rule ex_group_by_umi.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import pysam
import argparse

parser = argparse.ArgumentParser(description="Add UMI group BAM tag")
parser.add_argument("--input", required=True, help="Input BAM")
parser.add_argument("--output", required=True, help="Output BAM")
args = parser.parse_args()

print("[INFO] Starting ex_add_umi_group_tag.py")

bam_in = pysam.AlignmentFile(args.input, "rb")
bam_out = pysam.AlignmentFile(args.output, "wb", template=bam_in)

current_pair_name = None
current_mi = 0

# Temporary storage for the name of the first read in a pair
first_read_name = None

for read in bam_in:
    if current_pair_name is None:
        # Set MI tag for first read in a pair
        current_pair_name = read.query_name
        first_read_name = read
        read.set_tag("MI", str(current_mi), value_type="Z")

    elif read.query_name == current_pair_name:
        # Propagate MI to second read of the pair
        read.set_tag("MI", str(current_mi), value_type="Z")

        # Write both reads
        bam_out.write(first_read_name)
        bam_out.write(read)

        # Prepare for next pair
        current_mi += 1
        current_pair_name = None
        first_read_name = None
    else:
        # Warn for singletons or misordered BAM
        print(f"Warning: Unpaired read {read.query_name}")
        bam_out.write(read)

bam_in.close()
bam_out.close()

print("[INFO] Completed ex_add_umi_group_tag.py")