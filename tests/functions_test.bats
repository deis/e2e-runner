#!/usr/bin/env bats

# helmc-remove (entire file)

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/functions.sh"
}

@test "check-vars : none given" {
  repos=()
  run check-vars "${repos[@]}"

  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "check-vars : none to export" {
  repos=("FOO_REPO" "BAR_REPO")
  run check-vars "${repos[@]}"

  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "check-vars : some to export" {
  repos=("FOO_REPO" "BAR_REPO")
  export FOO_REPO_SHA="1234abcd"
  run check-vars "${repos[@]}"

  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${output}" == "Setting ${repos[0]}_GIT_TAG to git-${FOO_REPO_SHA:0:7}" ]
}

@test "check-vars : all to export" {
  repos=("FOO_REPO" "BAR_REPO")
  export FOO_REPO_SHA="1234abcd"
  export BAR_REPO_SHA="5678efgh"
  run check-vars "${repos[@]}"

  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" == "Setting ${repos[0]}_GIT_TAG to git-${FOO_REPO_SHA:0:7}" ]
  [ "${lines[1]}" == "Setting ${repos[1]}_GIT_TAG to git-${BAR_REPO_SHA:0:7}" ]
}
