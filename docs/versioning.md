# Versioning.md

Explanation of how semantic versioning is implemented in this codebase.

## Incrementing version numbers

Version numbers use the MAJOR.MINOR.PATCH format. 

Increment the relevant version number when making the following changes:

- **MAJOR**: Changes that affect variant calling
    - Example: Adding a new read-level filter

- **MINOR**: Changes that do not affect variant calling
    - Example: Adding a new metrics file

- **PATCH**: Changes that do not affect variant calling or metrics outputs
    - Example: Updating unit tests or documentation

## Required testing before merging into `master`

The following tests must be carried out before merging changes into `master`:

- **MAJOR**: 
    - All system level metrics pass
    - Includes all tests required for **MINOR** and **PATCH**

- **MINOR**: 
    - Pipeline runs successfully on 2+ full-size files
    - Runtime does not increase excessively
    - Includes all tests required for **PATCH**

- **PATCH**:
    - All unit/integration tests pass