# Changelog

All notable changes to this project will be documented in this file.

Types of changes:
- `MAJOR`
- `MINOR`
- `PATCH`

Each type of change has different validation requirements before it can be released. See `docs/development/versioning.md`

## [Unreleased]

### Minor
- Added ex_snv_read_position_metrics script, rule, and tests (#366)
- Added uniformity_SNV_read_position system metric (#366)

### Patch
- Changelog now groups changes into MAJOR/MINOR/PATCH rather than Added/Changed/Fixed (#363)
- Fixed bug that prevented rulegraph script from running (#364)
- Changed rulegraph format (#365)
- Moved random_seed from sci_params to infrastructure in config.yaml (#368)
- Updated user facing documentation (#369)

## [5.0.0] - 2026-03-13

### Added

- Added test to check that all rules have a test (#325)
- Added tests for various rules without tests (#338)
- Added random_seed to config.yaml (#339)
- Added germline risk variant and germline risk rate metrics (#342)
- Added metrics files and component metrics for multimapping reads (#343)
- Added component metric for germline risk rate (#347)
- Added LICENSE file (#355)

### Changed

- Refactored rules for germline risk masking (#327 and 352)
- Low depth mask is now set as the complement of positions eligible for germline risk calling (#327)
- Test scripts now used centralised paths (#323)
- Changed file paths for ex pipeline to improve readability (#330)
- Expected files test no longer depends on manually collated lists (#332)
- Consolidated trimming metrics into one file for ex and one for ms (#337)
- Set seed for pseudorandom selection of reads in ex_variant_call_eligible_disagree_rate.py (#339)
- Redirected fastqc progress messages from stdout to rule log files (#340)
- Metrics report now uses centralised paths (#341)
- Trinucleotide context cosine similarities CSV is now sorted by normalised values (#342)
- Mask metrics are now calculated for germ risk BEDs (#342 and 352)
- pytest_cache and pycache are now removed from all directories before and after running tests (#342)
- Combined ex_bases_trimmed and ex_trimmed_read_length_metrics into ex_trim_summary_metrics (#342)
- Removed hardcoded config paths from helper functions (#344)
- Removed hardcoded file paths from tests (#346)
- Decoupled shared setup and processing rules (#349)
- Centralised log and benchmark file paths (#350)
- Changed nn lower threshold for ex_unique_reads_initial_alignment from 58.3 to 50 (#351)
- Changed nn thresholds for external_concordance_blood, removed ideal thresholds (#351)
- Moved disk IOPs and throughput under create_run_timeline_plot key in config.yaml (#354)
- Updated docs in preparation for public release (#354)

### Fixed

- Test script names updated to match new rule names (#324)
- Cutadapt output no longer pollutes pipeline log (#337)
- Fixed bug in create_metrics_report.R where ex_lane IDs were split across rows (#358)

## [4.0.0] - 2026-02-26

### Added

- Added script for visualising rulegraphs (#307)
- Additional test cases for metrics report (#304)
- Added component metrics for median fragment length during library prep (#316) 

### Changed

- Removed hard coded config overrides from conftest.py (#308)
- Change to packaged outputs directory structure (#306)
- Refactored test_script directory (#309)
- Project root and package discovery now handled by conftest instead of individual test scripts (#309)
- Rules that use a single thread now explicitly declare this (#310)
- Updated thresholds for DNA fragment size component metrics (#311)
- Sample metadata for internal testing and external use now decoupled (#312)
- Removed hard coded paths from test_scripts (#312 and 315)
- Centralised rule file paths to definitions/paths directory (#317)
- Renamed scripts directory to rule_scripts (#318)
- Renamed "global" to "shared" throughout directories, rules, and config (#318)
- Refactored ex_demultiplex_fastq.py to avoid passing file paths as params (#320)
- Renamed tests/test_scripts directory to tests/scripts (#321)

### Removed
- Removed rules and associated files for EX technical controls (#319)

### Fixed

- Pipeline no longer crashes if lane names have underscores (#305)
- Unused *_end.fasta files no longer created by rule ex_generate_demux_adaptors (#305)
- Germline risk VCF is now a temp file (#303)
- Include flag now works for metrics report (#304)
- Fixed test case in test_ms_germline_risk.py following changes to test config (#314)
- ex_bases_trimmed.smk and ex_trimmed_read_length_metrics.smk now take r1 and r2 as input, instead of r1 twice (#317)

## [3.1.2] - 2026-02-02

### Changed

- Updated intermediate_files.md to improve clarity (#297)
- Moved setting of min-MQ parameter from ex_call_somatic_snv.smk to config.yaml (#298)

### Removed

- Removed deprecated ms_germ_risk_variant_metrics and ms_germ_risk_variant_metrics_summary (#300)

### Fixed

- Made implicit BAM index inputs explicit for multiple rules (#299)

## [3.1.1] - 2026-01-20

### Added

- Added intermediate_files.md with instructions for generating and storing intermediate files (#289)
- Added additional unit tests for ex_reference_trinuc_counts.py (#290)

### Changed

- Updated thresholds for EX depth and coverage component metrics (#291)

### Removed

- Temporarily removed ms_germline_risk_masking_rate from automated component metrics report (#294)

## [3.1.0] - 2026-01-19

### Added

- Added normalisation of trinucleotide counts to ex_trinucleotide_context_metrics.py (#288)
- Added additional unit tests for ex_trinucleotide_context_metrics.py (#288)

### Changed

- Moved various helper functions from individual scripts into the helpers directory (#288)

## [3.0.0] - 2026-01-12

### Added

- Added depth filter to ms_germline_risk.smk to mask low depth sites missed by samtools depth (#271)
- Added additional unit tests for ms_germline_risk.smk and ms_germline_mask.smk (#280 and 282)
- Added sort and merge steps to ms_germline_mask.smk to reduce BED size (#283)
- Added Sankey plot to ex_dsc_coverage_metrics.py (#284)
- Added ex_coverage_overlap_metrics.py and test (#284)
- Added ex_depth_metrics.py and test (#284)

### Changed

- Modified ms_germline_mask.smk to include low depth, REF only records in germline risk BED (#276)
- Moved combination of germline risk masks from combine_masks.smk to ms_germline_mask.smk (#280)
- Increased non-negotiable upper threshold for cross_reactivity_gnomAD_overlap system metric from 5 to 10 (#270)
- Raised nn lower threshold for uniformity_SNV_spacing from 100 to 120 (#278)
- Increased non-negotiable upper threshold for uniformity_SNV_position system metric from 15 to 20 (#278)
- Updated various component metric thresholds based on current data percentiles (#278)
- Added missing docstrings/comments and standardised style (#281)
- Removed hardcoded output paths in fastqc_summary_metrics.py, now passed to script by rules (#281)
- Passed individual parameters to ex_generate_demux_adaptors.py and ex_demux_counts_and_gini.py rather than all of config (#281)
- Moved overlap and depth metrics from ex_dsc_coverage_metrics.py into new scripts (#284)
- Rewrote ex_dsc_coverage_metrics.py to reduce memory usage (#284)

### Removed

- Removed gnomAD overlap rate calculation from ex_gnomAD_overlap.py (#275)
- Removed unused dependency gatk4 from environment.yml (#281)

## [2.2.0] - 2025-11-28

### Fixed

- Reduced thread allocation for rule ms_map to reduce memory usage (#267)

## [2.1.1] - 2025-11-20

### Changed

- Updated docs/config_checklist.md (#259)

### Fixed

- Updated S3 paths in config and docs (#260 and 261)

## [2.1.0] - 2025-11-17

### Added

- Added enforcement of memory limits to all rules (#250 and 251)
- Added extra_heavy memory allocation level (#255)
- Added all scripts to PATH and PYTHONPATH (#250)

### Changed
- Refactored directory structure of scripts and definitions (#250 and 254)
- Converted all python scripts into modules (#250)
- check_configs.py checks that ex_adapters are used only once per ex_lane (#252) 
- Adjusted memory allocation for various rules (#255)

## [2.0.0] - 2025-11-05

### Added

- Added ex_duplex_overlap_metrics, calculates the overlap between R1 and R2 for each duplex consensus sequence (#243)
- Added component metric for ex_duplex_overlap (#243)
- Abstracted pipeline output definitions from top-level snakefile to definitions/pipeline_outputs.smk (#238 and 239)

### Changed

- Swapped umi_tools dedup for fgbio GroupReadsByUmi, and fgbio SortBam and SetMateInformation for samtools sort and fixmate (#233)
- Updated default parameters for ex_call_dsc (Commit b17019d)
    - Increased min_input_base_quality from 10 to 30
    - Decreased max_duplex_disagreement_rate from 0.04 to 0.02
- Refactored rules file structure. Each smk file contains a single rule, and smk files are located in nested directory structure. (#239)
- Split component and system level metrics into separate reports (#245)
- External concordance in SNV rate now included in automated report (#246)
- Variant analyses now output to results/ dir instead of metrics/ dir (#240)
- Dependency made explicit for rules that depended on output lists, by importing definitions/pipeline_outputs.smk (#240)
- Config check script checks that experiment name is not default value (#237)
- SNVs per diploid genome uses new value for normalisation, derived from T2T-CHM13 (#236)
- Somatic variant rate metrics changed from TXT to JSON format, descriptions added (#236)
- SNV distance metrics computes additional percentiles (#231)
- bin/package_outputs.py now records checksums of all files it packages (#230)
- germline_contamination metric is now gnomAD_overlap, also calculates rate of SNVs overlapping with gnomAD per evaluated base (#229)

### Removed

- Removed rule that checks ex-ms mappings. This is also checked by check_config.py script (#232)

### Fixed

- Increased number of rounding digits for gnomAD overlap rate metric (#235)
- Uncommented ex_metrics in rule all of Snakefile (#234)
- Fixed bug in metrics report where SampleIDs were not correctly resolved for outputs in results directory (#242)

## [1.0.0] - 2025-10-23

### Added

- Initial release
