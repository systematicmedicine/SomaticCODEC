# branches.md

Guidleines for branches & pull requests

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
* `feature/description`
* `bugfix/description`
* `tests/description>`
* `refactor/<description>`
* `docs/<description>`

## Creating a new branch from dev

```
git fetch origin
git reset --hard origin/dev
git checkout -b my-new-feature
```

## Creating a pull request
* Bring branch up to date with dev and rebase
	+ Run tests and make sure your changes still work
* Go to codec-opensource repo on GitHub
* If you pushed recently, there will be a "Create Pull Request" banner
* Otherwise, go to the "Pull Requests" tab and click "New pull request"
* Change the base branch to dev (**defaults to main**)
* Change the compare branch to your feature/bugfix branch
* Add a description of your changes
* Select reviewers and an assignee (the person who will merge the pull request with dev)
* Click "Create pull request"
