# Troubleshooting

## Common problems

#### The pipeline is running slowly

- Make sure you have allocated enough memory and threads to each rule (balancing speed with parallelisation), and that disk throughput/IOPS are sufficient.
- The following files are useful for troubleshooting performance bottlenecks:
    - `logs/shared_rules/combined_benchmarks.csv`
    - `logs/shared_rules/run_timeline.pdf`
    - `logs/shared_rules/system_resource_usage.csv`

#### The pipeline crashed

- Check `logs/bin_scripts/run_pipeline.log`
- If a specific rule failed, check its log (e.g. `logs/{ex_sample}/ex_alignment.log`)

## Reporting bugs

If you encounter a bug while using SomaticCODEC, please report it via **GitHub Issues**.

When submitting a bug report, please include enough information for us to reproduce the issue. Useful context includes:

- A brief description of the experiment or analysis being performed
- Sample metadata files
- `tmp/runtime_config/merged_config.yaml`
- `logs/bin_scripts/run_pipeline.log`
- Logs of any rules that failed (e.g. `logs/{ex_sample}/ex_call_dsc.log`)
- A summary of compute environment used (e.g. OS, instance type, etc)

## Supported configurations

The pipeline is developed and tested using:
- The library preparation methods outlined in Phie *et al*. 2026 (currently under review)
- The `profiles` released with the repository 
- The `AWS m7i.48xlarge` compute platform and associated environment

Bug reports arising from **custom compute platforms, profiles, or alternative library preparation protocols** may receive limited support, as these configurations are outside of the validated assay setup.