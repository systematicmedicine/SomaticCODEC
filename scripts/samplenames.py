import pandas as pd

df = pd.read_csv(snakemake.input.mapping)
name_map = dict(zip(df["sample"], df["samplename"]))

def rename(infasta, outfasta):
    with open(infasta) as fin, open(outfasta, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                old = line.strip()[1:]
                new = name_map.get(old, old)
                fout.write(f">{new}\n")
            else:
                fout.write(line)

rename(snakemake.input.r1start, snakemake.output.r1start_out)
rename(snakemake.input.r1end,   snakemake.output.r1end_out)
rename(snakemake.input.r2start, snakemake.output.r2start_out)
rename(snakemake.input.r2end,   snakemake.output.r2end_out)