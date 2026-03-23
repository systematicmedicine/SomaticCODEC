# Software testing

SomaticCODEC uses the `pytest` framework to validate the correctness of the bioinformatics pipeline.

The purpose of testing is to ensure the pipeline behaves correctly in general, not to validate whether a specific run has been configured correctly.

## Test design

A central component of the test suite is the `lightweight_test_run` fixture. This runs the full pipeline on a small dataset (3 EX and 2 MS samples with a few thousand reads each) and completes in under 5 minutes on a standard PC.

Tests are structured as follows:

- **Unit tests**  
  Each rule that affects variant calling or metrics must have at least one unit test.

- **Integration tests**  
  Validate that the pipeline runs end-to-end, produces all expected output files, and that outputs contain data.

## Bug-driven testing

Bugs are addressed using a test-driven approach:

1. Understand the issue
2. Create a failing test that reproduces the bug
3. Implement a fix
4. Confirm the test passes

This ensures that bugs are captured as tests and do not regress in future changes.

## Running tests

Run the full test suite from the project root:

```bash
pytest
```

Run the abridged quick test suite (~10 seconds):

```bash
pytest -m quicktests
```