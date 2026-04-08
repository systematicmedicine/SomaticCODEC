# Selecting a profile

SomaticCODEC contains several profiles. Profiles are configuration bundles defining parameters for different use cases (e.g. primary human samples, cultured cells).

Profiles are defined in `/profiles`.

| Profile | Use case | Validated |
|---------|----------|-----------|
| `human-primary-snv` | Calling SNVs in primary human samples | TRUE |
| `test` | For software testing. Truncated reference genome for speed. | FALSE |

Use one of the existing profiles, or create a custom profile. When running the pipeline, a profile must be specified.