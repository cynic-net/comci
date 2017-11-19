load 'test-lib'

@test "git ci run: fails when missing arguments" {
    init_repo config

    run git ci run
    assert_failure
    assert_output --partial "'git ci run' requires a revision and a list of test-names"

    run git ci run foo
    assert_failure
    assert_output "fatal: Bad revision: foo"
}

@test "git ci run invalid revision/test name" {
    init_repo config

    run git ci run bad-branch-name test-pass
    assert_failure
    assert_output --partial "Bad revision: bad-branch-name"

    run git ci run master bad-test-name
    assert_failure
    assert_output --partial "Bad test name: bad-test-name"
}

@test "git ci run passing/failing" {
    init_repo config

    run git ci run master test-pass
    assert_success
    assert_output --partial 'passed:'

    run git ci run master test-fail
    assert_failure
    assert_output --partial 'failed:'
}

@test "git ci run check-status" {
    init_repo config

    run git ci run d2359a2 check-status
    assert_success
    assert_output --partial 'passed:'

    run git ci run 305871d check-status
    assert_failure
    assert_output --partial 'failed:'
}



@test "git ci run ... introduce-tests" {
    init_repo run
    git ci init

### Check that there are no results recorded

    run git ci show introduce-tests test1
    assert_output --partial 'No results'
    run git ci show introduce-tests test2
    assert_output --partial 'No results'

### Run test1, test2 on introduce-tests

    run git ci run introduce-tests test1 test2
    assert_output \
'a9c15b1 test-1 fails, test-2 succeeds, each writing to stderr and stdout

== running: test1

FLAMPing FLORMPLE
FATAL: FLORMPLE not FLAMPED

== failed: test1 on introduce-tests


a9c15b1 test-1 fails, test-2 succeeds, each writing to stderr and stdout

== running: test2

FLORMPLing FLAMPs
warn: too much sunshine.
Done.

== passed: test2 on introduce-tests'
    assert_failure

### Check that results are recorded now

    run git ci show introduce-tests test1 test2
    assert_output \
'a9c15b1 - test-1 fails, test-2 succeeds, each writing to stderr and stdout

    ### refs/ci/results/master:99afc201fbee690562b1a35cc722b11dc22e9a9b/test1/exit-code

    1

    ### refs/ci/results/master:99afc201fbee690562b1a35cc722b11dc22e9a9b/test1/output

    No results.

a9c15b1 - test-1 fails, test-2 succeeds, each writing to stderr and stdout

    ### refs/ci/results/master:99afc201fbee690562b1a35cc722b11dc22e9a9b/test2/exit-code

    0

    ### refs/ci/results/master:99afc201fbee690562b1a35cc722b11dc22e9a9b/test2/output

    No results.'
}



@test "git ci run ... test1-now-passing" {
    init_repo run
    git ci init

### Check that there are no results recorded

    run git ci show test1-now-passing test1
    assert_output --partial 'No results'
    run git ci show test1-now-passing test2
    assert_output --partial 'No results'

### Run test2 on test1-now-passing

    run git ci run test1-now-passing test2
    assert_output \
'214e1af test-1: passing: FLAMPing FLORMPLE

== running: test2

FLORMPLing FLAMPs
warn: too much sunshine.
Done.

== passed: test2 on test1-now-passing'
    assert_success
}
