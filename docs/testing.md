# testing.md

Guidelines for running tests on the CODECseq pipeline

## Integration tests using pytest

### tests directory
The tests directory contains test functions and fixtures to be used by pytest, as well as the following subdirectories:
* configs
    * Contains a distinct set of config files (e.g. config.yaml or sample.csv files) for each test
* data
    * Contains small data files that are used by one or more test functions
* snakefiles
    * Contains a distinct Snakefile for each test

### Writing a test
* .py files containing test functions must be named with the prefix "test_" to be found by pytest
* test_.py files may contain one or more test functions
* Each test function should:
    * Include "clean_workspace_fixture" as a parameter
        * This ensures that the workspace is cleaned before and after testing
    * Run a specific Snakefile that is created for that test
    * Assert that some condition has been met to return a pass result

### Running tests
* pytest should be run inside of a docker container to ensure all dependencies are met
* Avoid running tests in vscode as tests may fail due to permission/dependency issues
* All tests can be run in the command line by typing:
```
pytest

```
* The following flags can be useful when running pytest:
```
-v # verbose output, shows which test function/s failed within each test_.py file
-s # Shows all stdout/stderr output, useful when troubleshooting

```