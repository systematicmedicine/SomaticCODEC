# Versioning.md

Explanation of how semantic versioning is implemented in this codebase.

## Incrementing version numbers

Version numbers use the MAJOR.MINOR.PATCH format. 

The relevant version number is incremented when making the following changes:

- **MAJOR**: Changes that affect variant calling
    - Example: Adding a new read-level filter

- **MINOR**: Changes that do not affect variant calling
    - Example: Adding a new metrics file or updating resource allocation to a rule

- **PATCH**: Changes that do not affect variant calling, metrics outputs, or performance
    - Example: Updating unit tests or documentation

## Required testing before merging into `master`

The following tests must be carried out before merging changes into `master`:

- **MAJOR**: 
    - All tests required for **MINOR** and **PATCH**
    - All system level metrics pass

- **MINOR**: 
    - All tests required for **PATCH**
    - Pipeline runs successfully on 2+ full-size files
    - Runtime does not increase excessively

- **PATCH**:
    - All unit/integration tests pass