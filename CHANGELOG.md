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

### Changed

- SNV distnace metrics computes additional percentiles (#231)
- bin/package_outputs.py now records checksums of all files it packages (#230)
- germline_contamination metric is now gnomAD_overlap, calculates rate of SNVs overlapping with gnomAD per evaluated base (#229)

### Removed

- Removed rule that checks ex-ms mappings. This is also checked by check_config.py script (#232)

## [1.0.0] - 2025-10-23

### Added

- Initial release