load 'bats-assert/load'
load 'bats-support/load'

testing_harness='tmp/test'

init_repo() {
    local test_repo="$testing_harness/repo01"
    rm -rf "$testing_harness"
    git clone t/fixtures/repo01.git "$test_repo"
    cd "$test_repo"
}

@test "list repo01 tests" {
    init_repo
    run git ci list
    assert_output "
        test-pass
        test-fail
    "
    assert_success
}
