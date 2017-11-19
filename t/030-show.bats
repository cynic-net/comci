load 'test-lib'

@test "git ci show ... check-status" {
    init_repo config

    run git ci show d2359a2 check-status
    assert_output 'd2359a2 - test (new), status (new): add passing test

    ### refs/ci/results/master:2dc7858d38de371cb2c1ca87e6c081e3a5638ea3/check-status/exit-code

    0

    ### refs/ci/results/master:2dc7858d38de371cb2c1ca87e6c081e3a5638ea3/check-status/output

    No results.'
    assert_success

    run git ci show 305871d check-status
    assert_output '305871d - status: failing test

    ### refs/ci/results/master:28695280d933cd06665790c54e379d18849924c4/check-status/exit-code

    1

    ### refs/ci/results/master:28695280d933cd06665790c54e379d18849924c4/check-status/output

    This is garbage output
Some more output'
    assert_success

    run git ci show 1111111 check-status
    assert_output --partial 'Not a commit: 1111111'
    assert_failure

    run git ci show 45feee8 check-status
    assert_output '45feee8 - 

    ### refs/ci/results/master:4b825dc642cb6eb9a060e54bf8d69288fbee4904/check-status/exit-code

    No results.

    ### refs/ci/results/master:4b825dc642cb6eb9a060e54bf8d69288fbee4904/check-status/output

    No results.'
    assert_success

    run git ci show 305871d bad-test-name
    assert_output 'fatal: Bad test name: bad-test-name'
    assert_failure
}
