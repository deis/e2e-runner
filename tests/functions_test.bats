#!/usr/bin/env bats

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

@test "set-chart-values-from-env : none in env" {
  run set-chart-values-from-env

  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "set-chart-values-from-env : one in env" {
  POSTGRES_GIT_TAG='git-abc1234'
  run set-chart-values-from-env

  [ "${status}" -eq 0 ]
  [ "${output}" = "database.docker_tag=git-abc1234" ]
}

@test "set-chart-values-from-env : multiple in env" {
  POSTGRES_GIT_TAG='git-abc1234'
  NSQ_GIT_TAG='git-def5678'
  CONTROLLER_GIT_TAG='git-ghi9123'
  FOO_GIT_TAG='git-xxx0000'
  run set-chart-values-from-env

  [ "${status}" -eq 0 ]
  [ "${output}" = "nsqd.docker_tag=git-def5678,database.docker_tag=git-abc1234,controller.docker_tag=git-ghi9123" ]
}

@test "get-chart-repo : non-production" {
  run get-chart-repo 'foo' 'dev'

  [ "${status}" -eq 0 ]
  [ "${output}" == 'foo-dev' ]
}

@test "get-chart-repo : production" {
  run get-chart-repo 'foo' 'production'

  [ "${status}" -eq 0 ]
  [ "${output}" == 'foo' ]
}
