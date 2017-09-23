git-ci
======

Our CI world is about tests run in many [worktree]s (often hundreds).
For a given repo, each developer is likely to have several worktrees
on his computer in which he runs tests, there may be CI servers may
have one or more worktrees each also running tests, and so on.

The results of test runs should be stored in a way that can be
transferered between repos; using a git branch is the obvious way to
do this.

Intended Interface
------------------

-   `git ci list [options]`: List the tests and reports in the repository.
    Without options, just prints out the names. With option `--verbose` prints
    out command and dependencies. Option `--deps`/`--recursive` also calls
    `git ci list $@` on the test dependencies?

-   `git ci run [options] [rev-spec]* [--] <test-name>*`: Run a specified test
    on the revisions (defaults to `HEAD`). If the tests dependencies haven't
    haven't been run yet, then run those first (unless the option `--no-deps` is
    given). Test results are recorded using the recording scheme below. By
    default will not rerun tests that results exist for, option `--force` will
    override existing test-results.

-   `git ci show [commit-ish] <report-name>*`: Show the output of tests
    `<test-name>*` on commit `[commit-ish]`. Defaults to `HEAD`.

-   `git ci log [options] [rev-spec]* [--] <report-name>*`: Runs `git log` but
    appends test results. Takes a superset of the options of `git log`.

-   `git ci forget [rev-spec]* [--] <test-name>*`: Removes specified recorded
    test-results from repository.

-   `git ci config`: Takes all the normal `git config` options but applies them
    to file `config` on branch `ci/config`.

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

Recording Test Results
----------------------

A particular test result is identified by:

  1. The name of the test suite. (LV1: n dozen)
  2. The tree object from which the working copy was created.
     (We do not store results of tests on dirty working copies.)
     (LV2: 26*26 = ~1k, LV3: <5k)
  3. The worktree in which the test was run, identified by:
       a. User name (or name of test system)
       b. Host identifier of some sort (Name? MAC address?)
       c. Path to tree or hash of it or whatever?
     (LV4: ~100)

LVn indicates the directory tree level within a tree object and the
approximate count of files within it.

A test result should store, beyond the identification info above:
  * Host and user running test
  * git author?
  * Host configuration (OS and tools version etc.)
  * env vars
  * pass/fail status
  * stdout/stderr

Test results are added to the "distributed database" of test results
by commiting on the test result branches for that repo under `git-ci`.
Each worktree commits test results to its own individual subdir so
that merges can always be done automatically. Test results can be
put on any branch under `git-ci`.

Small groups where test results are pushed less frequently would probably
have everybody committing results on to `git-ci/master`; if a new
comit can't be pushed, the committer can pull, merge or rebase his
results on to `remote/git-ci/master` and push it up with little
likelyhood that during this time someone else will have pushed new
commits on to that branch.

Large groups with a high rate of adding test results can commit to
different branches under `git-ci/` and merges can be done to
`git-ci/master` less frequently by whichever hosts find it convenient
to do that. Programs that process test results will always look at all
branches under `git-ci/` for results so that results not merged into
`git-ci/master` are not missed.

[worktree]: https://git-scm.com/docs/git-worktree

Different Tests
---------------

The "test that was run" can be recorded as the command that was run
(e.g., "./Test --units-only", "rake test", etc.). But we probably want
some way of assigning short names to these commands; local (per-repo)
configuration might do for this, or we might have a separate branch
that contains the configuration file, configuring the short names,
commands, and what commits (commit ranges) these commands can be run
on. Probably the version of the configuration used should be recorded
in the test result.

One problem is that you might create a new test, "./Other-test" in a
commit and want to run that test in previous commits. We need a way to
add that "./Other-test" file to the tree of previous commits when we
do the test run, and record which version of that "./Other-test" file
was used.

Possibly we could include extra scripts in the configuration branch
mentioned above, or have some sort of configuration directive that
says, "take these files from the tree objects of these commits and add
them to the working copy of the commit we're testing." (This is a bit
like `git submodule`.)
