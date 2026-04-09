# Change control

The `master` branch of the SomaticCODEC repository is change controlled. 

Semantic versioning is used to track changes between versions (MAJOR, MINOR, PATCH, e.g. `v3.1.0`). The type of validation required prior to a `master` release depends on the level of the change. 

## Change levels

If a change meets the criteria for multiple levels, increment the version number by the highest level (MAJOR > MINOR > PATCH).

### MAJOR - could affect variant calling
Any change to files that are involved in converting pipeline inputs into a VCF of called variants. 

- `rules/`
- `rule_scripts/`
- `helpers/`
- `definitions/`
- `bin/create_runtime_config.py`
- `bin/run_pipeline.py`
- `bin/run_all.sh`
- `profiles/<profile_name>/profile.yaml`
- `Dockerfile`
- `dependencies.yml`
- `Snakefile`

Exceptions:
- Rules, scripts, definitions or parameters that can only affect metrics generation
- Changes only involving comments or whitespace

Validation required = `Scientific performance` + `Computational stability` + `Software testing`

### MINOR - could affect computational stability

Any change that could affect the computational stability of the pipeline in production. Whitespace and comments exempt.

- `rules/`
- `rule_scripts/`
- `helpers/`
- `bin/`
- `environments/<environment_name>/environment.yaml`
- `profiles/<profile_name>/profile.yaml`
- `Dockerfile`
- `dependencies.yml`
- `Snakefile`

Exceptions:
- Changes only involving comments or whitespace

Validation required = `Computational stability` + `Software testing`

### PATCH - all other changes

Any other change to the repository. Common examples include:
- `tests/`
- `docs/`
- `README.md`
- `profiles/<profile_name>/component_level_metrics.xlsx`
- `profiles/<profile_name>/system_level_metrics.xlsx`

Validation required = `Software testing`

## Types of validation

### Scientific performance

For scientific performance validation there are two options, `Performance Characterisation` and `Demonstrating Equivalence`.

*Option 1 - Performance Characterisation*

Performance Characterisation is used when changes have been made to the pipeline with the intent of altering performance. In general, a change to `master` is only made if there is a net improvement in assay performance.

- `human-primary-snv`
    - Linearity dataset
        - R-squared with 95% CI
    - Precision dataset
        - Normalised IQR with 95% CI
    - General testing dataset
        - All remaining system-level metrics
        - Component level metrics (excluding library-prep)

*Option 2 - Demonstrating Equivalence*

Demonstrating Equivalence is used when changes made to the pipeline were not intended to alter performance. The purpose of the validation is to provide evidence that no meaningful change in performance has occurred.

- `human-primary-snv`
    - General testing dataset
        - Called variants are identical to previous MAJOR version

### Computational stability

- Pipeline runs without crashing on 12 typical sized EX/MS sample pairs
- Pipeline runtime is characterised

In general, a major deterioration in pipeline runtime requires commensurate benefit to justify.

### Software testing

- All unit and integration tests pass
- Every rule that affects variant calling or scientific metrics must have at least 1 unit test
- Every fixed bug must have at least 1 unit test that reproduces failure

## Releasing a new version

New `master` versions are created from the `dev` branch. To release a new `master` version:

1. Update `CHANGELOG.md` on the `dev` branch, replacing `Unreleased` with the incremented version number (e.g. `3.1.0`)

2. Create a release branch from `dev`

```bash
git switch dev
git fetch origin
git reset --hard origin/dev
git switch -c release/<vN.N.N>
git push -u origin release/<vN.N.N>
```

3. Perform the required validation

4. Following successful validation, merge `release/<vN.N.N>` into `master` via a pull request (at least 1 reviewer required)

5. Add a tag for the release

```bash
git switch master
git fetch origin
git reset --hard origin/master
git tag -a <vN.N.N> -m "SomaticCODEC release <vN.N.N>"
git push origin --tags
```

6. Merge `master` back into `dev` (via a pull request) to ensure commit parity
