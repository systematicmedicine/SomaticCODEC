# Change control

The `master` branch of the SomaticCODEC repository is change controlled. 

Semantic versioning is used to track changes between versions (MAJOR, MINOR, PATCH, e.g. `v3.1.0`). The type of validation required prior to a `master` release depends on the level of the change. 

## Change levels

If a change meets the criteria for multiple levels, increment the version number by the highest level (MAJOR > MINOR > PATCH).

### MAJOR - Affects variant calling

Changes that affect variant calling performance.

Validation required = `Scientific performance (Performance Characterisation)` + `Computational stability` + `Software testing`

### MINOR - Affects metrics or computational performance

Changes that do not affect variant calling performance, but do affect metrics or computational performance.

Validation required = `Computational stability` + `Software testing`

If any change is made to a file that is involved in variant calling, `Scientific performance (Demonstrating Equivalence)` must also be validated.

### PATCH - All other changes

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

Demonstrating Equivalence is used when changes made to the pipeline were not intended to alter performance. The purpose of the validation is to provide evidence that no meaningful change in variant calling performance has occurred.

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
- Every fixed bug must have at least 1 unit test that reproduces the failure

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
