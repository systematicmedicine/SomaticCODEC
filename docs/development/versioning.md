# Versioning & releases

The SomaticCODEC repository uses semantic versioning, with levels of validation depending on the scope of the change. Version numbers use the MAJOR.MINOR.PATCH format (e.g. `v3.0.1`).

## Change levels

### MAJOR - Changes that could affect variant calling

Examples:
- Changing any rule or script that could affect variant calling (excluding comments or whitespace)
- Changing any configurable parameter that could affect variant calling
- Changing the Dockerfile or dependencies.yml

### MINOR -  Changes that could affect computational stability

Examples: 
- Updating resource allocation to a rule
- Adding any new rule with uncharacterised computational performance

### PATCH - Changes that can't affect variant calling or computational stability

Examples:
- Changing metrics configurations
- Adding unit tests
- Updating documentation

## Types of validation

### Scientific performance
    
For each validated profile affected by the change:
- Characterise performance of all system level metrics, including system level metrics that require specialised datasets such as linearity and precision.
- Characterise performance of all component-level metrics (excluding library-prep metrics)

Note: scientific performance testing only tests the core pipeline underlying variant calling, it does not assess the validity of assay performance metrics.

### Computational stability

- Pipeline runs without crashing on 12 typical sized EX/MS sample pairs
- Pipeline runtime is characterised

### Software testing
- All unit and integration tests pass
- Every rule that affects variant calling or scientific metrics must have at least 1 unit test
- Every fixed bug must have at least 1 unit test that reproduces failure

## Validation requirements

The following validation must be performed before updating the `master` branch.

### MAJOR

`Scientific performance` + `Computational stability` + `Software testing`

### MINOR

`Computational stability` + `Software testing`

### PATCH

`Software testing`

