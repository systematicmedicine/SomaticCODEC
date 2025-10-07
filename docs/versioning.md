# Versioning.md

Explanation of how semantic versioning is implmeneted in this codebase.

- **MAJOR**: Changes that influence variant calling, anticipated to have a significant impact
    - Example: FASTQ files have an additional filter applied
- **MINOR**: Changes that influence variant calling, not anticipated to have a significant impact
    - Example: A much faster de-ducplication algorithm is used that is functionally similar to the previous implementaton, but not identical.
- **PATCH** Changes that do not influence variant calling
    - Example: New metrics file, unit tests or documentation