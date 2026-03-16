# Versioning.md

Explanation of how semantic versioning is implemented in this codebase.

## Incrementing version numbers

Version numbers use the MAJOR.MINOR.PATCH format. 

The relevant version number is incremented when making the following changes:

- **MAJOR**: Changes that could affect variant calling
    - Example: Changing the tool used to call variants
    - Example: Changing the default paramemter for read quality filtering
    - Example: Changing the Dockerfile

- **MINOR**: Changes that could affect computational performance/stability, but not variant calling
    - Example: Updating resource allocation to a rule
    - Example: Adding a new scientific metric that calculates genomic coverage
    - Example: Adding an innocent little metrics script that shouldn't effect performance...

- **PATCH**: Changes that can't affect variant calling or computational performance/stability
    - Example: Changing metrics report configuration (component_metrics.xlsx, system_metrics.xlsx)
    - Example: Adding new unit tests
    - Example: Updating documentation

## Required testing before merging into `master`

The following tests must be carried out before merging changes into `master`:

- **MAJOR**: 
    - All tests required for **MINOR** and **PATCH**
    - All system and component level metrics are assessed. Net improvement in assay performance.

- **MINOR**: 
    - All tests required for **PATCH**
    - Pipeline runs successfully on a batch of 12 full-size files
    - Changes to runtime and disk usage are acceptable

- **PATCH**:
    - All unit/integration tests pass
    - Every rule that affects variant calling or scientific metrics must have atleast 1 unit test