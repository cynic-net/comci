git-ci
======

Our CI world is about tests run in many [worktree]s (often hundreds). For a
given repo, each developer is likely to have several worktrees on his computer
in which he runs tests, there may be CI servers may have one or more worktrees
each also running tests, and so on.

The results of test runs should be stored in a way that can be transferered
between repos; using a git branch is the obvious way to do this.

Individual machines can contribute to the "distributed database" of test results
by commiting to the test result branches under `refs/ci/results`. Each worktree
commits test results to its own individual subdir so that merges can always be
done automatically.

[worktree]: https://git-scm.com/docs/git-worktree

Interface
---------

### Partially Implemented

-   `git ci init`: Creates `refs/ci/config:config`, an empty config file for the
    repository to use. Also creates `refs/ci/results/master` with an empty
    initial commit.

    -   Currently only creates `refs/ci/results/master`, but should also create
        `refs/ci/config`.

-   `git ci list [options]`: List the tests and reports in the repository.
    Without options, just prints out the names. With option `--verbose` prints
    out command and dependencies. Option `--deps`/`--recursive` also calls
    `git ci list $@` on the test dependencies?

    -   None of the `[options]` are implemented.

-   `git ci run [options] [rev-spec]* [--] <test-name>*`: Run a specified test
    on the revisions (defaults to `HEAD`). If the tests dependencies haven't
    haven't been run yet, then run those first (unless the option `--no-deps` is
    given). Test results are recorded using the recording scheme below. By
    default will not rerun tests that results exist for, option `--force` will
    override existing test-results.

    -   Currently only records exit codes, should record stdout/stderr.
    -   Currently only takes `[revision]`, generalize to `[rev-spec]`.

-   `git ci show [commit-ish] <report-name>*`: Show the output of tests
    `<test-name>*` on commit `[commit-ish]`. Defaults to `HEAD`.

    -   Does not default to `HEAD` if no `commit-ish` supplied.
    -   Does not default to all tests if no `report-name` supplied.

-   `git ci config [options]`: Takes all the normal `git config` options but
    applies them to file `config` on branch `ci/config`.

    -   Currently only able to read config file, not write to it.

### Unimplemented

-   `git ci log [options] [rev-spec]* [--] <report-name>*`: Runs `git log` but
    appends test results. Takes a superset of the options of `git log`.

-   `git ci pull/push [options]`: Push/pull results to remote. Takes same
    options as `git push/pull`?

-   `git ci forget [rev-spec]* [--] <test-name>*`: Removes specified recorded
    test-results from repository.

-   `git ci prune` forget results for unreachable commits

### Workflow

Test results can be put on any branch under `refs/ci/results`. People can choose
their own branch structure underneath `refs/ci/results` (depending on
organization size/needs).

Small groups where test results are pushed less frequently would probably have
everybody committing results on to `refs/ci/results/master`; if a new commit
can't be pushed, the committer can pull, merge or rebase his results on to
`refs/remotes/ci/results/master` and push it up with little likelyhood that
during this time someone else will have pushed new commits on to that branch.

In larger groups, test results can be committed to different branches under
`refs/ci/results` and merged back into `refs/ci/results/master` by whichever
hosts find it convenient to do that. Programs that process test results can
always look at all branches under `refs/ci/results` for results so that results
not merged into `refs/ci/results/master` are not missed.

Configuration Format
--------------------

The file `config` on `ci/config` will specify the configuration to run `git ci`
with. It uses the git configuration format. Two types of entries are supported,
the `test` entry and the `report` entry. Every `test` entry is also implicitly a
`report` entry.

### Tests

Tests are commands which are to be executed against work-trees of the specified
commits. They implicitly have a `report` associated with them. Test results are
stored by `git ci` in `refs/ci/results`.

Here is an example of specifying tests:

```
[test "units"]
    command = ./Build test-units

[test "integration"]
    command = ./Build test-all
    deps = units
```

This says that the test name `units` is run with the command
`./Build test-units`. Similarly for `integration`, but also it's specified that
this test should not be run without results for `units` being preset.

TODO: Clarify the test names that we allow (and potentially restrict them more).

### Reports

Reports are used to display test results for `git ci log`. Each test entry has
an implicit report which is just the output of the test. Results of reports are
not stored anywhere.

Exit codes that are non-zero indicate fatal errors with generating the report
itself, not the status of the tests passing or not.

Here is an example of specifying a report:

```
[report "performance"]
    command = summarize-performance
    deps = integration
```

This specifies that the report `performance` calls the script
`summarize-performance` which is stored in `ci/config` in the `/bin` directory.
It will be called with the `[commit-ish]` that `git ci log` calculates.

### Future

The revspec that a test should be run on should be recorded in the
`ci/config:config`. This would allow specifying how far back a test should be
considered valid.

Recording Test Results
----------------------

A particular test result is identified by:

1.  The tree object from which the working copy was created. We do not store
    results of tests on dirty working copies. (LV1: 26*26 = ~1k, LV3: <5k)
2.  The name of the test suite. (LV2: n dozen)
3.  The worktree in which the test was run, identified by:
    a.  User name (or name of test system)
    b.  Host identifier of some sort (Name? MAC address?)
    c.  Path to tree or hash of it or whatever?
    (LV4: ~100)

LVn indicates the directory tree level within a tree object and the approximate
count of files within it.

When doing `git ci show`, the user is asking for (potentially) multiple test
results from a given commit, so we want to be able to quickly access multiple
test-names within a given tree. When doing a `git ci log`, the revision list
(and then tree list) will be calculated ahead of time, then multiple test
results will be accessed for each tree in order (so we still want faster access
to results by test name).

Currently, we are identifying test results by tree SHA and test name. The
structure is `refs/ci/results/*:tree-sha/test-name` -- we don't store
host/worktree information. The `*` allows the user to specify test result branch
structure they want to use.

The test results should contain (in principle, though needs may differ):

-   Relevant host configuration (OS and tools version etc.)
-   A dump of environment variables.
-   Test pass/fail status.
-   stdout/stderr of test runs.
-   SHA of `refs/ci/config:config`.
