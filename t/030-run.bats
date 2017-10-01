load 'test-lib'

@test "git ci run: fails when missing arguments" {
    init_repo config

    run git ci run
    assert_failure
    assert_output --partial "'git ci run' requires a revision and a test-name"

    run git ci run foo
    assert_failure
    assert_output --partial "'git ci run' requires a revision and a test-name"

    run git ci run 1 2 3 4
    assert_failure
    assert_output --partial "Too many arguments"
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
