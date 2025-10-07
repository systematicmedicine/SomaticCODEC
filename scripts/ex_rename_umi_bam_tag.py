"""
--- ex_rename_umi_bam_tag.py ---

Takes the output of umi_tools group and makes the following modifications to the BAM tags:
    - Removes the BX tag
    - Replaces the UG:i tag with MI:Z
    - Adds the UG:i tag from R1 to R2

To be used exclusively within rule ex_annotate_map.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import pysam
import argparse

parser = argparse.ArgumentParser(description="Rename UMI BAM tag")
parser.add_argument("--input", required=True, help="Input BAM")
parser.add_argument("--output", required=True, help="Output BAM")
args = parser.parse_args()

bam_in = pysam.AlignmentFile(args.input, "rb")
bam_out = pysam.AlignmentFile(args.output, "wb", template=bam_in)

prev_name = None
prev_mi = None

for read in bam_in:
    # Remove BX tag
    if read.has_tag("BX"):
        read.set_tag("BX", None)

    # Replace UG:i with MI:Z
    if read.has_tag("UG"):
        mi_value = str(read.get_tag("UG"))
        read.set_tag("MI", mi_value, value_type="Z")
        read.set_tag("UG", None)
        # store for the next read (mate)
        prev_name = read.query_name
        prev_mi = mi_value
    else:
        # propagate MI from previous read (after ensuring names match)
        if read.query_name == prev_name and prev_mi is not None:
            read.set_tag("MI", prev_mi, value_type="Z")
        else:
            prev_name = read.query_name
            prev_mi = None

    bam_out.write(read)

bam_in.close()
bam_out.close()

print("[INFO] Completed ex_rename_umi_bam_tag.py")