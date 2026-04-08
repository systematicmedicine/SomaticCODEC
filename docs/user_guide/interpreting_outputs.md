# Interpreting pipeline outputs

## Called variants

A VCF containing all called SNVs can be found in `results/{ex_sample}/{ex_sample}_called_snvs.vcf`

SNV rate can be found in `results/{ex_sample}/{ex_sample}_somatic_variant_rate.json`

## Assay performance metrics

### System level

System-level metrics measure the performance of the entire assay. 

There are two types of system-level metics:
- Metrics assessed for every sample or batch
- Metrics that require specialised datasets (e.g. linearity, precision)

The pipeline reports all system-level metrics that can be assessed on every sample or batch. The report can be found at `results/system_metrics_report.csv`. The description for each metric can be found in `profiles/<profile>/system_level_metrics.xlsx`. 


### Component level

Component-level metrics measure the performance of individual assay components. 

There are two types of component-level metics:
- Metrics assessed during library prep
- metrics assessed bioinformatically

The pipeline reports all component-level metrics that are assessed bioinformatically. The report can be found at `metrics/component_metrics_report.csv`. The description for each metric can be found in `profiles/<profile>/component_level_metrics.xlsx`. 

### Reporting thresholds

Thresholds for each component and system level metric were established using a combination of internal data (~20 batches) and first-principles reasoning.

These thresholds are intended as a guide for troubleshooting assay performance. Results may differ if different wet-lab, sequencing, or bioinformatic parameters are used.

### Other metrics
Additional metrics files are generated that are not included in the automated report. These can be found in the `metrics/` and `results/` directories.

Some notable files:

- `results/{ex_sample}/{ex_sample}_trinuc_plots_normalised.pdf`
- `results/{ex_sample}/{ex_sample}_snv_position_plot.pdf`
- `metrics/ex/{ex_sample}/{ex_sample}_dsc_coverage_plot.html`
- `metrics/ex/{ex_sample}/{ex_sample}_insert_metrics.pdf`
- `metrics/ms/{ms_sample}/{ms_sample}_insert_metrics.pdf`

<br>

<p align="left">
  <img src="../figures/example_trinuc_context.png" width="1200">
</p>

*Example trinucleotide context report, comparing the sample to several reference contexts*