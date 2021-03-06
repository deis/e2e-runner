#!/usr/bin/env bats

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/deis.sh"
  load stub
  load stubs/tpl/kubectl
}

teardown() {
  rm_stubs
}

@test "clean_cluster : cluster already clean" {
  ns_output="bar"
  stub kubectl "$(generate ${ns_output})" 0

  run clean_cluster
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "Cluster already clean." ]
}

@test "clean_cluster : cluster not clean and namespaces don't go away" {
  export DEFAULT_TIMEOUT_SECS=1
  stub delete-lease

  ns_output="deis"
  stub kubectl "$(generate ${ns_output})" 0

  run clean_cluster
  echo "${output}"
  [ "${status}" -eq 1 ]
  [ "${lines[0]}" = "Deis was installed so I'm removing it!" ]
  [ "${lines[1]}" = "Waiting for namespace to go away!" ]
  [ "${lines[2]}" = "Namespace was never deleted" ]
}
