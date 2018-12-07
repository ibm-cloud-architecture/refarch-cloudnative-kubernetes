## Contributing to IBM Cloud Architecture reference applications
Anyone can contribute to IBM Cloud Architecture reference applications and their associated projects, whether you are an IBMer or not.
We welcome your collaboration & contributions happily, as our reference applications are meant to reflect your real world scenarios.
There are multiple ways to contribute: report bugs and improvement suggestions, improve documentation, and contribute code.


## Bug reports, documentation changes, and feature requests

If you would like to contribute your experience with an IBM Cloud Architecture project back to the project in the form of encountered bug reports, necessary documentation changes, or new feature requests, this can be done through the use of the repository's [**Issues**](#) list.  

Before opening a new issue, please reference the existing list to make sure a similar or duplicate item does not already exist.  Otherwise, please be as explicit as possible when creating the new item and be sure to include the following:

- **Bug reports**
  - Specific Project Version
  - Deployment environment
  - A minimal, but complete, setup of steps to recreate the problem
- **Documentation changes**
  - URL to existing incorrect or incomplete documentation (either in the project's GitHub repo or external product documentation)
  - Updates required to correct current inconsistency
  - If possible, a link to a project fork, sample, or workflow to expose the gap in documentation.
- **Feature requests**
  - Complete description of project feature request, including but not limited to, components of the existing project that are impacted, as well as additional components that may need to be created.
  - A minimal, but complete, setup of steps to recreate environment necessary to identify the new feature's current gap.

The more explicit and thorough you are in opening GitHub Issues, the more efficient your interaction with the maintainers will be.  When creating the GitHub Issue for your bug report, documentation change, or feature request, be sure to add as many relevant labels as necessary (that are defined for that specific project).  These will vary by project, but will be helpful to the maintainers in quickly triaging your new GitHub issues.

## Code contributions

We really value contributions, and to maximize the impact of code contributions, we request that any contributions follow the guidelines below.  If you are new to open source contribution and would like some more pointers or guidance, you may want to check out [**Your First PR**](http://yourfirstpr.github.io/) and [**First Timers Only**](https://www.firsttimersonly.com/).  These are a few projects that help on-board new contributors to the overall process.

### Coding and Pull Requests best practices
- Please ensure you follow the coding standard and code formatting used throughout the existing code base.
  - This may vary project by project, but any specific diversion from normal language standards will be explicitly noted.
- One feature / bug fix / documentation update per pull request
  - Always pull the latest changes from upstream and rebase before creating any pull request.  
  - New pull requests should be created against the `integration` branch of the repository, if available.
  - This ensures new code is included in full-stack integration tests before being merged into the `master` branch
- All new features must be accompanied by associated tests.
  - Make sure all tests pass locally before submitting a pull request.
  - Include tests with every feature enhancement, improve tests with every bug fix

### Github and git flow

The internet is littered with guides and information on how to use and understand git.
However, here's a compact guide that follows the suggested workflow

![Github flow](https://ibm-cloud-architecture.github.io/assets/img/github_flow.png)

1. Fork the desired repo in github.

2. Clone your repo to your local computer.

3. Add the upstream repository

    Note: Guide for step 1-3 here: [forking a repo](https://help.github.com/articles/fork-a-repo/)

4. Create new development branch off the targeted upstream branch.  This will often be `master`.

    ```
    git checkout -b <my-feature-branch> master
    ```

5. Do your work:
   - Write your code
   - Write your tests
   - Pass your tests locally
   - Commit your intermediate changes as you go and as appropriate
   - Repeat until satisfied

6. Fetch latest upstream changes (in case other changes had been delivered upstream while you were developing your new feature).

    ```
    git fetch upstream
    ```
7. Rebase to the latest upstream changes, resolving any conflicts. This will 'replay' your local commits, one by one, after the changes delivered upstream while you were locally developing, letting you manually resolve any conflict.

    ```
    git branch --set-upstream-to=upstream/master
    git rebase
    ```
    Instructions on how to manually resolve a conflict and commit the new change or skip your local replayed commit will be presented on screen by the git CLI.

8. Push the changes to your repository

    ```
    git push origin <my-feature-branch>
    ```

9. Create a pull request against the same targeted upstream branch.

    [Creating a pull request](https://help.github.com/articles/creating-a-pull-request/)

Once the pull request has been reviewed, accepted and merged into the main github repository, you should synchronise your remote and local forked github repository `master` branch with the upstream master branch. To do so:

10. Pull to your local forked repository the latest changes upstream (that is, the pull request).

    ```
    git pull upstream master
    ```

11. Push those latest upstream changes pulled locally to your remote forked repository.

    ```
    git push origin master
    ```

### What happens next?
- All pull requests will be automatically built and unit tested by travis-ci, when implemented by that specific project.
  - You can determine if a given project is enabled for travis-ci unit tests by the existence of a `.travis.yml` file in the root of the repository or branch.
  - When in use, all travis-ci unit tests must pass completely before any further review or discussion takes place.
- The repository maintainer will then inspect the commit and, if accepted, will pull the code into the upstream branch.
- Should a maintainer or reviewer ask for changes to be made to the pull request, these can be made locally and pushed to your forked repository and branch.
- Commits passing this stage will make it into the next release cycle for the given project.
