git-ci
======

Our CI world is about tests run in many [worktree]s (often hundreds).
For a given repo, each developer is likely to have several worktrees
on his computer in which he runs tests, there may be CI servers may
have one or more worktrees each also running tests, and so on.

The results of test runs should be stored in a way that can be
transferered between repos; using a git branch is the obvious way to
do this.

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
