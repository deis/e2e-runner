#!/bin/bash

tail_logs_from_e2e_pod() {
  echo "Waiting for e2e pod to become ready"
  wait-for-pod-ready "${WORKFLOW_E2E_CHART}"
  kubectl logs -f --namespace=deis -c tests "${WORKFLOW_E2E_CHART}"
  return-pod-exit-code "${WORKFLOW_E2E_CHART}"
  return $?
}

retrive-artifacts() {
  local exitCode=0
  echo "Retrieving junit.xml from the artifacts sidecar container"
  kubectl exec -c artifacts --namespace=deis "${WORKFLOW_E2E_CHART}" -- /bin/sh -c "find /root -name junit*.xml" > "${DEIS_LOG_DIR}/all-junit-files.out"
  exitCode=$?
  while read -r file || [[ -n "${file}" ]]
  do
    kubectl exec -c artifacts --namespace=deis "${WORKFLOW_E2E_CHART}" cat "${file}" > "${DEIS_LOG_DIR}/$(basename "$file")"
    (( exitCode += $? ))
  done < "${DEIS_LOG_DIR}/all-junit-files.out"
}

return-pod-exit-code() {
  local name="${1}"
  command_output="$(kubectl get po "${name}" -a --namespace=deis -o json | jq -r --arg container "tests" '.status.containerStatuses[] | select(.name==$container) | .state.terminated.exitCode')"

  if [ "${command_output}" == "null" ]; then
    return 0
  fi
  return $command_output
}

wait-for-pod-ready() {
  local name="${1}"
  local timeout_secs=15
  local increment_secs=1
  local waited_time=0
  local command_output

  while [ ${waited_time} -lt ${timeout_secs} ]; do
    test_container_output="$(kubectl get po "${name}" -a --namespace=deis -o json | jq -r --arg container "tests" '.status.containerStatuses[] | select(.name==$container) | .ready')"
    artifact_container_output="$(kubectl get po "${name}" -a --namespace=deis -o json | jq -r --arg container "artifacts" '.status.containerStatuses[] | select(.name==$container) | .ready')"

    if [ "${test_container_output}" == "true" ] && [ "${artifact_container_output}" == "true" ]; then
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += ${increment_secs} ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo
      echo "${WORKFLOW_E2E_CHART} was never ready. Test Container:${test_container_output} -- Artifact Container:${artifact_container_output}"
      delete_lease
      exit 1
    fi

    echo -n . 1>&2
  done
}
