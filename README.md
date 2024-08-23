comci: Committed Continuous Integration Results
===============================================

Comci (pronounced /COM si/ or /com SI/) is a system for running unit and
integration tests for a Git commit and storing the results of those tests
in the Git repo, associated with the Git commit against which they were
run.

This is an aid to [_continuous integration,_][ci] a concept from [Extreme
Programming][xp] where the entire system as currently under development is
tested very frequently: at least once per day but preferably more often.
These tests may be started manually (by simply running `git tscript`
frequently) or assissted by a system that runs the tests automatically,
without explicit requests by the developer.

### Usage Overview

The unit and integration tests for a system are divided up into a set of
test scripts, or _tscripts;_ each tscript may optionally take a single
parameter. Comci adds a `tscript` sub-command to Git to manage running the
tests, viewing and transfering the results, and the like. A typical
session might be:

    $ git commit -m 'my new changes'

    #   Run three test scripts from the full set: 'unit' and 'brief' with
    #   no parameters passed to them, and 'int' with the parameter 'foo'
    #   and 'bar'. These will be run in the background on new working
    #   copies from that commit (a separate working copy for each test) and
    #   the user will be informed as each one completes.

    $ git tscript run @ unit brief int,foo int,bar

    #   Here the user can do other things while waiting for the tests to
    #   complete. For example, run tests against the the _current_ working
    #   copy (`-i`/`--interactive` option) instead of a commit. This will
    #   be run in the foreground and the results will not be recorded to git.

    $ vi foo.py
    $ git tscript run -i . unit

    $ git commit -m 'FIXUP: Clean up blah blah blah'

    #   After completion the results can be examined:

    $ git log -2            # A Git note will summarise the results
    $ git tscript show @^   # Shows details of the tests we ran at the
                            # start against the parent of our fixup commit.

    #   If all is happy, you can generate a new commit with your cleanup
    #   and the full set of tests for it. This will run all test scripts
    #   under tscript/, including 'int' several times with each parameter
    #   from a list of all the parameters in tscript/int.params.

    $ git rebase -i         # Squash fixups into final commit.
    $ git tscript run @     # Run all tests against this new commit. If the
                            # commit has already had some tests run against
                            # it, this will run only the not-yet-run tests.
                            # Since test results are linked to the commit's
                            # tree, squashing commits will not force
                            # re-running tests.

    #   You can work on something else while these run in the background.

    $ git push                      # Make code available for review.
    $ git checkout dev/cjs/other    # Hack on different code.
    ...
    $ git checkout -                # When tests are complete.
    $ git push                      # Make test results available for review.



<!-------------------------------------------------------------------->
[ci]: https://en.wikipedia.org/wiki/Continuous_integration
[xp]: https://en.wikipedia.org/wiki/Extreme_programming
