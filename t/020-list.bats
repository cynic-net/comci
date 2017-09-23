load test-lib

# unit tests
# ----------

@test "parse_config" {
    . bin/git-ci --define-functions-only
    parse_config <<EOF
        test.test-pass.command true
        test.test-fail.command false other parameters
EOF

    assert_equal "${test_names[0]}" test-pass
    assert_equal "${test_names[1]}" test-fail
    assert_equal "${#test_names[@]}" 2

    assert_equal "${test_commands[0]}" true
    assert_equal "${test_commands[1]}" "false other parameters"
    assert_equal "${#test_commands[@]}" 2
}

@test "parse_config: Unsupported test option" {
    . bin/git-ci --define-functions-only
    run parse_config >/dev/null <<EOF
        test.test-fail.new-option value
EOF
    assert_success
    assert_output "== warning: Unsupported test option: 'new-option' (test test-fail new-option value)"
}

# functional tests
# ----------------

@test "git ci list: repo-config" {
    init_repo config
    run git ci list
    assert_output "test-pass
test-fail"
    assert_success
}

@test "git ci list: fail on non-existant configuration" {
    init_repo no-config
    run git ci list
    assert_output "==   fatal: Couldn't find ref refs/ci/config"
    assert_failure

    git update-ref refs/ci/config @
    run git ci list
    assert_output "==   fatal: config file doesn't exist on refs/ci/config"
    assert_failure

}
