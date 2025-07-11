# Logging.md

## Rules that use the shell directive
* Add the log directive to the rule `logs/{wildcard}/rule_name.log`
* Add the benchmark directive to the rule `logs/{wildcard}/rule_name.benchmark.txt`
* Append `2>> {log}` at the end of each shell command. Put it on the final line, do not use \ to put it on a new line.

Example:
```
rule combine_masks:
    input:
        ...
    output:
        ...
    log:
        "logs/{ms_sample}/combine_masks.log"
    benchmark:
        "logs/{ms_sample}/combine_masks.benchmark.txt"
shell:
    """
    cat {input.gnomAD_bed} \
    {input.GIAB_bed} \
    {input.ms_lowdepth_bed} \
    {input.ms_germ_del_bed} \
    {input.ms_germ_ins_bed} \
    {input.ms_germ_snv_bed} > {output.intermediate_cat} 2>> {log}
    
    sort {output.intermediate_cat} -k1,1 -k2,2n > {output.intermediate_sorted} 2>> {log}

    bedtools merge -i {output.intermediate_sorted} > {output.combined_bed} 2>> {log}
    """
```

## Rules that use the script directive
* Add the log directive to the rule `logs/{wildcard}/rule_name.log`
* Add the benchmark directive to the rule `logs/{wildcard}/rule_name.benchmark.txt`
* For Python scripts
    * Add `sys.stdout = open(snakemake.log[0], "a")` at the start of the script
    * Add `sys.stderr = open(snakemake.log[0], "a")` at the start of th script
    * Capture all outputs from subrpocess calls (see example below)
* For R scripts
    * At the start of the script add `log_con <- file(snakemake@log[[1]], open = "wt")`, `sink(log_con)` and `sink(log_con, type = "message")`
    * At the end of the script add `sink(type = "message")`, `sink()` and `close(log_con)`
* Add started and completed statements to script (optional)

Example (Python):
```
""" script.py """

import sys

# Redirect stdout and stderr to the Snakemake log file
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting script.py")

# Script does some stuff
...

cmd = [ ... ] # shell command defined within python list object

with open(snakemake.log[0], "a") as log_file:
    subprocess.run(cmd, check=True, stdout=log_file, stderr=log_file)

# Script does some more stuff

print("[INFO] Completed script.py")
...
```

Example (R):
```
""" script.R """

# Logging setup
log_con <- file(snakemake@log[[1]], open = "wt")
sink(log_con)
sink(log_con, type = "message")


# Script does some stuff
...

# Clean up logging
sink(type = "message")
sink()
close(log_con)
```