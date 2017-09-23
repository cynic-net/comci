load 'bats-assert/load'
load 'bats-support/load'

# utilities/settings
# ------------------

testing_harness='tmp/test'

init_repo() {
    local repo_name="$1"
    local test_repo="$testing_harness/repo-$repo_name"
    rm -rf "$test_repo"
    git clone --quiet t/fixtures/repo-$repo_name.git "$test_repo"
    cd "$test_repo"
    git fetch --quiet
    git show-ref --quiet --verify refs/remotes/origin/ci/config || return 0
    git branch --quiet ci/config origin/ci/config
}