load test-lib

# unit tests
# ----------

@test "set_test_names" {
    . bin/git-ci --define-functions-only

    init_repo config

    run set_test_names
    assert_success
    assert_output -p "Invalid test name: 'test name with spaces'"

    set_test_names &>/dev/null

    assert_equal "${test_names[0]}" "test-pass"
    assert_equal "${test_names[1]}" "test-fail"
    assert_equal "${test_names[2]}" "failing-subcommand"
    assert_equal "${test_names[3]}" "check-status"
    assert_equal "${test_names[4]}" "extra-params"
    assert_equal "${test_names[5]}" "test-dots"
    assert_equal "${test_names[6]}" "test/slash"
    assert_equal "${test_names[7]}" "test.slash"
    assert_equal "${#test_names[@]}" 8

    assert_equal "$(get_test_command "test-pass")"          "true"
    assert_equal "$(get_test_command "test-fail")"          "false"
    assert_equal "$(get_test_command "failing-subcommand")" "false; echo 'Passed?!'"
    assert_equal "$(get_test_command "check-status")"       "./test"
    assert_equal "$(get_test_command "extra-params")"       "false other params"
    assert_equal "$(get_test_command "test-dots")"          "test.with.dots ..."
    assert_equal "$(get_test_command "test/slash")"         "test stuff"
    assert_equal "$(get_test_command "test.slash")"         "/test/with/slash"
}

# functional tests
# ----------------

@test "git ci list: repo-config" {
    init_repo config
    run git ci list
    assert_output "== warning: Invalid test name: 'test name with spaces'
test-pass
test-fail
failing-subcommand
check-status
extra-params
test-dots
test/slash
test.slash"
    assert_success
}

@test "git ci list: fail on non-existant configuration" {
    init_repo no-config
    run git ci list
    assert_output "==   fatal: Couldn't find branch ci/config"
    assert_failure

    git branch ci/config @
    run git ci list
    assert_output "==   fatal: config file doesn't exist on branch ci/config"
    assert_failure

}
