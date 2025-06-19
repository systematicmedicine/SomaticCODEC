import re

vcf_path = snakemake.input.vcf_all
output_path = snakemake.output.results

starting_bases = 0
filtered_bases = 0
evaluated_bases = 0
num_snv_bases = 0
min_bq = "NA"
min_mq = "NA"

with open(vcf_path) as f:
    for line in f:
        if line.startswith("##bcftoolsCommand="):
            # Extract --min-BQ and --min-MQ from the header line
            bq_match = re.search(r"--min-BQ\s+(\d+)", line)
            mq_match = re.search(r"--min-MQ\s+(\d+)", line)
            if bq_match:
                min_bq = bq_match.group(1)
            if mq_match:
                min_mq = mq_match.group(1)

    f.seek(0)  # Rewind to process data lines
    for line in f:
        if line.startswith("#"):
            continue

        cols = line.strip().split("\t")
        assert len(cols) >= 9, f"Malformed line with too few columns:\n{line}"

        info = dict(field.split("=", 1) for field in cols[7].split(";") if "=" in field)
        sample_fmt = cols[8].split(":")
        sample_vals = cols[9].split(":")
        fmt = dict(zip(sample_fmt, sample_vals))

        dp_info = int(info.get("DP", 0))  # Raw read depth
        dp_fmt = int(fmt.get("DP", 0))    # High-quality read depth
        ad_vals = [int(x) for x in fmt.get("AD", "").split(",")]

        starting_bases += dp_info
        filtered_bases += dp_info - dp_fmt
        evaluated_bases += dp_fmt
        num_snv_bases += sum(ad_vals[1:]) if len(ad_vals) > 1 else 0

snv_rate = num_snv_bases / evaluated_bases if evaluated_bases > 0 else 0
snv_per_6Gbp = snv_rate * 6_000_000_000

with open(output_path, "w") as out:
    out.write("metric\tvalue\n")
    out.write(f"starting_bases\t{starting_bases}\n")
    out.write(f"min-BQ\t{min_bq}\n")
    out.write(f"min-MQ\t{min_mq}\n")
    out.write(f"filtered_bases\t{filtered_bases}\n")
    out.write(f"evaluated_bases\t{evaluated_bases}\n")
    out.write(f"num_snv_bases\t{num_snv_bases}\n")
    out.write(f"snv_rate\t{snv_rate:.6e}\n")
    out.write(f"snv_per_6Gbp\t{snv_per_6Gbp:.2f}\n")