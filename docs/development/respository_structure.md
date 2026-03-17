# Repository structure

| Path | Purpose |
|------|---------|
| `bin/` | User-facing scripts for pipeline orchestration |
| `config/` | Configuration files defining pipeline parameters |
| `definitions/` | Centralised definitions of pipeline outputs and path constants |
| `docs/` | Pipeline documentation
| `helpers/` | Shared functionality used by multiple scripts and rules |
| `logs/` | Runtime logs and benchmark files |
| `metrics/` | Per-sample metrics generated during pipeline execution |
| `results/` | Final assay outputs, including called variants and derived results |
| `rule_scripts/` | Scripts that fully implement the logic of individual pipeline rules |
| `rules/` | Modular Snakemake rule definitions |
| `tests/` | Pytest test suite and associated reference data |
| `tmp/` | Intermediate files generated during runtime and temporary downloads of input files |
| `Dockerfile`, `environment.yml` | Define the reproducible computational environment |
| `Snakefile` | Top-level Snakemake file that orchestrates pipeline execution |