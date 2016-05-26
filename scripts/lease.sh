#!/bin/bash

lease() {
  eval $(k8s-claimer --server=k8s-claimer-e2e.deis.com lease create --duration=$CLUSTER_DURATION)
  echo "Leased cluster $CLUSTER_NAME for $CLUSTER_DURATION seconds"
  echo "TOKEN: $TOKEN"
  if [ -z $TOKEN ]; then
    echo "Lease failed exiting."
    exit 1
  fi
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
