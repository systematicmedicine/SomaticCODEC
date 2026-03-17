# Versioning & releases

## Types of changes

- **MAJOR**: <B>Changes that could affect variant calling </b>
    - Example: Changing the tool used to call variants
    - Example: Changing the default paramemter for read quality filtering
    - Example: Changing the Dockerfile

- **MINOR**: <B>Changes that could affect computational performance/stability</b>
    - Example: Updating resource allocation to a rule
    - Example: Adding a new scientific metric that calculates genomic coverage
    - Example: Adding an innocent little metrics script that shouldn't affect performance...

- **PATCH**: <B>Changes that can't affect variant calling or computational performance/stability</b>
    - Example: Changing metrics report configuration (component_metrics.xlsx, system_metrics.xlsx)
    - Example: Adding new unit tests
    - Example: Updating documentation

## Validation required to release a new version

The validation required before updating the `master` branch depends on the scope of the changes. If multiple changes, use the highest level of change.

- **MAJOR**: 
    - All validation required for **MINOR** and **PATCH**
    - All system and component level metrics are assessed. Net improvement in assay performance.

- **MINOR**: 
    - All validation required for **PATCH**
    - Pipeline runs successfully on a batch of atleast 12 samples of typical file size
    - Changes to runtime and disk usage are acceptable

- **PATCH**:
    - All unit and integration tests pass
    - Every rule that affects variant calling or scientific metrics must have atleast 1 unit test

## Semantic versioning

Version numbers use the MAJOR.MINOR.PATCH format (e.g. `v3.0.1`).