load 'test-lib'

@test "git ci run: fails when missing arguments" {
    run git ci run
    assert_failure
    assert_output -p "'git ci run' requires a revision and a test-name"

    run git ci run foo
    assert_failure
    assert_output -p "'git ci run' requires a revision and a test-name"

    run git ci run 1 2 3 4
    assert_failure
    assert_output -p "Too many arguments"
}
