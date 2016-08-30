#!/bin/bash

lease() {
  local tries=1
  local cluster_args

  cluster_args="--duration ${CLUSTER_DURATION}"
  if [ -n "${CLUSTER_REGEX}" ]; then
    cluster_args="${cluster_args} --cluster-regex ${CLUSTER_REGEX}"
  elif [ -n "${CLUSTER_VERSION}" ]; then
    cluster_args="${cluster_args} --cluster-version ${CLUSTER_VERSION}"
  fi

  echo "Requesting lease with: '${cluster_args}'"
  while [ -z "$TOKEN" ]; do
    # shellcheck disable=SC2086
    eval "$(k8s-claimer --server=k8s-claimer-e2e.deis.com lease create ${cluster_args})"
    if [ -n "$TOKEN" ]; then
      echo "Leased cluster '${CLUSTER_NAME}' for $CLUSTER_DURATION seconds"
      echo "TOKEN: $TOKEN"
      return 0
    fi

    if [ ${tries} -eq "${LEASE_RETRIES}" ]; then
      echo "Acquiring lease failed."
      exit 1
    fi
    (( tries += 1 ))
  done
}

# Uninstall deis when we are done and delete lease
delete-lease() {
  echo "Gather pod logs before we delete lease"
  get-pod-logs
  echo "Uninstalling ${WORKFLOW_CHART}"
  kubectl delete namespace "deis" &> /dev/null
  echo "Deleting all test namespaces"
  kubectl get namespace | grep test | awk '{print $1}' | xargs kubectl delete namespace &> /dev/null
  echo "Deleting Lease for ${CLUSTER_NAME} -- ${TOKEN}"
  k8s-claimer --server=k8s-claimer-e2e.deis.com lease delete "${TOKEN}"
  return 0
}
