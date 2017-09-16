load 'bats-assert/load'
load 'bats-support/load'

# utilities/settings
# ------------------

testing_harness='tmp/test'

init_repo() {
    local repo_num="$1"
    local test_repo="$testing_harness/repo$repo_num"
    rm -rf "$test_repo"
    git clone --quiet t/fixtures/repo$repo_num.git "$test_repo"
    cd "$test_repo"
    git config --local remote.origin.fetch '+refs/ci/config:refs/ci/config'
    git fetch --quiet
}

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

@test "git ci list: repo01" {
    init_repo 01
    run git ci list
    assert_output "test-pass
test-fail"
    assert_success
}
