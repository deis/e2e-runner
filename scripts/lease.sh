#!/bin/bash

lease() {
  local tries=1
  while [ -z "$TOKEN" ]; do
    eval $(k8s-claimer --server=k8s-claimer-e2e.deis.com lease create --duration=$CLUSTER_DURATION)
    if [ -n "$TOKEN" ]; then
      echo "Leased cluster $CLUSTER_NAME for $CLUSTER_DURATION seconds"
      echo "TOKEN: $TOKEN"
      return 0
    fi

    if [ ${tries} -eq ${LEASE_RETRIES} ]; then
      echo "Aquiring lease failed."
      exit 1
    fi
    (( tries += 1 ))
  done
}

delete_lease() {
  # Uninstall deis when we are done
  echo "Uninstalling ${WORKFLOW_CHART}"
  kubectl delete namespace "deis" &> /dev/null
  echo "Deleting all test namespaces"
  kubectl get namespace | grep test | awk '{print $1}' | xargs kubectl delete namespace &> /dev/null
  echo "Deleting Lease for ${CLUSTER_NAME} -- ${TOKEN}"
  k8s-claimer --server=k8s-claimer-e2e.deis.com lease delete $TOKEN
  return $?
}
