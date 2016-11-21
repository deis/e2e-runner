#!/usr/bin/env bats

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/helm.sh"
}

@test "set-chart-values : none in env" {
  run set-chart-values

  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "set-chart-values : workflow, one in env" {
  POSTGRES_SHA='abc123456789'
  run set-chart-values workflow

  [ "${status}" -eq 0 ]
  [ "${output}" = "--set database.docker_tag=git-abc1234" ]
}

@test "set-chart-values : workflow, multiple in env" {
  POSTGRES_SHA='abc123456789'
  NSQ_SHA='def567891234'
  CONTROLLER_SHA='ghi912345678'
  FOO_SHA='xxx000000000'
  run set-chart-values workflow

  [ "${status}" -eq 0 ]
  [ "${output}" = "--set nsqd.docker_tag=git-def5678,database.docker_tag=git-abc1234,controller.docker_tag=git-ghi9123" ]
}

@test "set-chart-values : workflow-e2e" {
  WORKFLOW_E2E_SHA='abc123456789'
  run set-chart-values workflow-e2e

  [ "${status}" -eq 0 ]
  [ "${output}" = "--set docker_tag=git-abc1234" ]
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
