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
* `feature/description`
* `bugfix/description`
* `tests/description>`
* `refactor/<description>`
* `docs/<description>`

## Working with multiple branches

### Checking local and remote branches

* List local branches (current branch marked with *)
```
git branch 
```

* List remote branches
```
git branch -a
```

### Creating a new branch from dev

* Switch to local dev branch
```
git switch dev
```

* Update local dev branch from remote
```
git pull origin dev
```

* Create new local branch from dev and switch to it
```
git switch -c <branch-name>
```

### Creating remote branch from local branch

* Make changes on local branch, then stage and commit
```
git add <file_name>
git commit -m "<message>"
```

* Create remote branch and push local commits
```
git push -u origin feature/<branch-name>
```

### Adding uncommitted changes to a different branch

* Stash uncommitted changes (they can be staged or unstaged)
  * This will remove the changes from your working directory and store them in a hidden folder
  * Your current branch will remain unchanged
```
git stash
```
	

* Change to a different branch
```
git switch <branch-name>
```

* Bring changes back to working directory
```
git stash pop
```

* Stage, commit, and push changes when ready

### Keeping branches up to date with dev

* Push any local commits
```
git push origin <branch-name>
```

* Get changes from remote dev branch
```
git fetch origin dev
```

* Rebase local commits on top of up-to-date dev
```
git rebase origin/dev
```

* Push rebased local commits to remote feature branch
  * This is required because your commits exist both locally and on the remote (even after pushing)
  * Rebasing changes the hash of your local commits, but does not change the hash of their corresponding commits on the remote
  * This means that after rebasing, your local commits have different hashes to their remote pairs (even though their content is identical)
  * --force-with-lease will only replace remote commits with the new local copy (with the new hash) if the remote branch has not changed since you last pulled from it
  * This prevents overwriting anything that was pushed to the same branch (by someone else) while you were rebasing
  * **--force (without lease) should be avoided** as this will overwrite anything that was pushed to the same branch while you were rebasing
```
git push --force-with-lease
```

### Creating a pull request

* Bring branch up to date with dev and rebase as above
	+ Run tests and make sure your changes still work
* Go to codec-opensource repo on GitHub
* If you pushed recently, there will be a "Create Pull Request" banner
* Otherwise, go to the "Pull Requests" tab and click "New pull request"
* Change the base branch to dev (**defaults to main**)
* Change the compare branch to your feature/bugfix branch
* Add a description of your changes
* Select reviewers and an assignee (the person who will merge the pull request with dev)
* Click "Create pull request"
