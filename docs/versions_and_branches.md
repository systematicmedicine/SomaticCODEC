# versions_and_branches.md

The purpose of this doc is to describe respoitory versioning and branch structure

## Branch structure

### Overview

* `master` branch is used by the end user
* `dev` branch is a candidate master branch
* `feature` branches implement changes to the repository

### Naming conventions
* `feature/description`
* `bugfix/description`
* `tests/description>`
* `refactor/<description>`
* `docs/<description>`

## Versioning

`master` branch adheres to semantic versioning. The table below outlines the criteria for each level, and testing required before a pull request can be made from `dev` to `master`.

| Level 	| Criteria 														| Testing required 								|
|----------	|---------------------------------------------------------------|-----------------------------------------------|
| MAJOR    	| Changes that effect variant calling, and change the DAG  		| All system and component level metrics pass	|
| MINOR    	| Changes that effect variant calling, but don't change the DAG | All componet level metrics pass   			|
| MINOR    	| Changes that do not effect variant calling (e.g. metrics)  	| All unit & integration tests pass 			|

`dev` and `feature` brnaches do not use semantic versioning.

### Pull requests to dev
1. Create unit tests for any new rules created (optional for metrics rules)
2. Rebase to dev 
3. Run test suite. Check that all tests pass
4. Initiate pull request (select `dev`, not `master`)
5. Assign R&D manager as reviewer if DAG changes (excluding metrics rules)
6. Delete feature branch if it is no longer required (locally & remote)

### Creating a new featrure branch
```
git fetch origin
git reset --hard origin/dev
git checkout -b feature/your-short-description
git push -u origin feature/your-short-description
```
