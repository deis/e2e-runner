#!/usr/bin/env bats

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/helm.sh"
}

@test "set-chart-version : none in env" {
  run set-chart-version

  [ "${status}" -eq 0 ]
  [ "${output}" == "" ]
}

@test "set-chart-version : workflow" {
  WORKFLOW_TAG="v1.2.3"
  run set-chart-version workflow

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Installing workflow chart workflow-v1.2.3" ]
  [ "${lines[1]}" == "--version v1.2.3" ]
}

@test "set-chart-version : workflow-e2e" {
  WORKFLOW_E2E_TAG="v1.2.3"
  run set-chart-version workflow-e2e

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Installing workflow-e2e chart workflow-e2e-v1.2.3" ]
  [ "${lines[1]}" == "--version v1.2.3" ]
}

@test "set-chart-values : none in env" {
  run set-chart-values

  [ "${status}" -eq 0 ]
  [ "${output}" == "" ]
}

@test "set-chart-values : workflow, one in env" {
  POSTGRES_SHA='abc123456789'
  run set-chart-values workflow

  [ "${status}" -eq 0 ]
  [ "${output}" == "--set database.docker_tag=git-abc1234" ]
}

@test "set-chart-values : workflow, multiple in env" {
  POSTGRES_SHA='abc123456789'
  NSQ_SHA='def567891234'
  CONTROLLER_SHA='ghi912345678'
  FOO_SHA='xxx000000000'
  run set-chart-values workflow

  [ "${status}" -eq 0 ]
  [ "${output}" == "--set nsqd.docker_tag=git-def5678,database.docker_tag=git-abc1234,controller.docker_tag=git-ghi9123" ]
}

@test "set-chart-values : workflow-e2e" {
  WORKFLOW_E2E_SHA='abc123456789'
  WORKFLOW_CLI_SHA='def567891234'
  run set-chart-values workflow-e2e

  [ "${status}" -eq 0 ]
  [ "${output}" == "--set docker_tag=git-abc1234,cli_version=def5678" ]
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

@test "get-chart-repo : workflow staging" {
  run get-chart-repo 'workflow' 'staging'

  [ "${status}" -eq 0 ]
  [ "${output}" == 'workflow-staging' ]
}

@test "get-chart-repo : component staging" {
  run get-chart-repo 'component' 'staging'

  [ "${status}" -eq 0 ]
  [ "${output}" == 'component' ]
}
