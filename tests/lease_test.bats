#!/usr/bin/env bats

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/lease.sh"
  load stub
  load stubs/tpl/k8s-claimer

  LEASE_RETRIES=2
  CLUSTER_DURATION=10
  CLOUD_PROVIDER=azure
  LEASE_CREATE_OUTPUT="\
    export TOKEN=foo \
    export CLUSTER_NAME=cluzter \
  "

  stub k8s-claimer "$(generate "${LEASE_CREATE_OUTPUT}")" 0
}

teardown() {
  rm_stubs
}

@test "lease : (create) lease failed" {
  stub k8s-claimer "" 0

  run lease

  [ "${status}" -eq 1 ]
  [ "${lines[0]}" == "Requesting lease with: '--duration ${CLUSTER_DURATION} --provider=${CLOUD_PROVIDER}'" ]
  [ "${lines[1]}" == "Acquiring lease failed." ]
}

@test "lease : (create) cluster args - just duration" {
  run lease

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Requesting lease with: '--duration ${CLUSTER_DURATION} --provider=${CLOUD_PROVIDER}'" ]
  [ "${lines[1]}" == "Leased cluster 'cluzter' for ${CLUSTER_DURATION} seconds" ]
  [ "${lines[2]}" == "TOKEN: foo" ]
}

@test "lease : (create) cluster args - duration and cluster regex" {
  CLUSTER_REGEX="\"my fave cluster\""

  run lease

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Requesting lease with: '--duration ${CLUSTER_DURATION} --provider=${CLOUD_PROVIDER} --cluster-regex ${CLUSTER_REGEX}'" ]
}

@test "lease : (create) cluster args - duration and cluster version" {
  CLUSTER_VERSION="1.2.3"

  run lease

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Requesting lease with: '--duration ${CLUSTER_DURATION} --provider=${CLOUD_PROVIDER} --cluster-version ${CLUSTER_VERSION}'" ]
}

@test "lease : (create) cluster args - duration, cluster regex and cluster version (cluster regex wins)" {
  CLUSTER_REGEX="\"my fave cluster\""
  CLUSTER_VERSION="1.2.3"

  run lease

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Requesting lease with: '--duration ${CLUSTER_DURATION} --provider=${CLOUD_PROVIDER} --cluster-regex ${CLUSTER_REGEX}'" ]
}

# delete lease

@test "delete-lease" {
  CLUSTER_NAME=cluzter
  TOKEN=foo

  stub get-pod-logs "" 0
  stub kubectl "" 0
  stub k8s-claimer "" 0

  run delete-lease

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" == "Gather pod logs before we delete lease" ]
  [ "${lines[1]}" == "Uninstalling Workflow" ]
  [ "${lines[2]}" == "Deleting all test namespaces" ]
  [ "${lines[3]}" == "Deleting Lease for ${CLUSTER_NAME} -- ${TOKEN}" ]
}
