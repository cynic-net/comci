load 'test-lib'

@test "git-ci prints help message" {
    run git ci
    assert_output --partial "usage: git ci"
    assert_failure

    run git ci -h
    assert_output --partial "usage: git ci"
    assert_success

    run git ci help
    assert_output --partial "usage: git ci"
    assert_success
}
