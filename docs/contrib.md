# contrib.md

Guidleines for contributing to this repository

## Branch structure

Feature branches -> dev branch -> master branch

* The master branch is a stable branch used by the end user
* The dev branch is a candidate master branch, but requires testing first
* Feature branches implement new features

## Pull requests

### dev -> master
* Pipeline run end-end on full size files
* At least 8 ex samples in the same run
* Non-negotiable component level targets met (all samples)

### feature -> dev
* All rules that are changed (or created) must be covered by atleast one integration test
* All relevant integration tests pass

## Integration tests
* Test that <u>sets</u> of rules generate expected outputs
* Use a testing framework (e.g. pytest)
* Use toy files < 1MB (e.g. 100 line FASTQs). Where possible re-use files between tests (e.g. GCRh38-micro.fa)
* When bugs in the pipeline are found, add integration tests that prevent this bug reccuring

## Branch naming conventions
Use the following naming conventions for feature branches:
* feature/<description>
* bugfix/<description>
* tests/<description>
* refactor/<description>
* docs/<description>