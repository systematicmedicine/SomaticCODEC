# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

Types of changes:
- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.

## [Unreleased]

### Added

- Added depth filter to ms_germline_risk to mask low depth sites missed by samtools depth (#271)
- Added additional unit tests for ms_germline_risk and ms_germline_mask (#280 and 282)
- Added sort and merge steps to ms_germline_mask to reduce BED size (#283)

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
