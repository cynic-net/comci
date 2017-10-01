load 'test-lib'

@test "cat_test_results" {
    . bin/git-ci --define-functions-only
    init_repo config

    run cat_test_results master d2359a2 check-status
    assert_success
    assert_output '0'

    run cat_test_results master 305871d check-status
    assert_success
    assert_output '1'
}

@test "git ci show ... check-status" {
    init_repo config

    run git ci show d2359a2 check-status
    assert_success
    assert_output 'exit-status: 0'

    run git ci show 305871d check-status
    assert_success
    assert_output 'exit-code:

1'

    run git ci show 45feee8 check-status
    assert_success
    assert_output 'No results recorded.'

    run git ci show 305871d bad-test-name
    assert_failure
    assert_output 'Bad test name: bad-test-name'

    run git ci show 1111111 check-status
    assert_failure
    assert_output -p 'Bad revision: 1111111'
}
