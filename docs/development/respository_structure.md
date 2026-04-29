# Repository structure

| Path | Purpose |
|------|---------|
| `bin/` | User-facing scripts for pipeline orchestration |
| `definitions/` | Centralised definitions of pipeline outputs and path constants |
| `docs/` | Pipeline documentation |
| `environments/` | Compute platform specific configuration (e.g. memory allocation) |
| `experiment/` | Run specific metadata e.g. sample sheets |
| `helpers/` | Shared functionality used by multiple scripts and rules |
| `logs/` | Runtime logs and benchmark files |
| `metrics/` | Per-sample metrics generated during pipeline execution |
| `profiles/` | Predefined configuration bundles for different assay use cases |
| `results/` | Final assay outputs, including called variants and derived results |
| `rule_scripts/` | Scripts that fully implement the logic of individual pipeline rules |
| `rules/` | Modular Snakemake rule definitions |
| `tests/` | Pytest test suite and associated reference data |
| `tmp/` | Intermediate files generated during runtime and temporary downloads of input files |
| `Dockerfile`, `dependencies.yml` | Define the containerised software environment (Docker image and dependencies) |
| `Snakefile` | Top-level Snakemake file that orchestrates pipeline execution |