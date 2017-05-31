#!/bin/bash

tail_logs_from_e2e_pod() {
  kubectl logs -f --namespace=deis -c tests workflow-e2e
  return-pod-exit-code workflow-e2e
  return $?
}

retrive-artifacts() {
  echo "Retrieving junit.xml from the artifacts sidecar container"
  kubectl exec -c artifacts --namespace=deis workflow-e2e -- /bin/sh -c "find /root -name junit*.xml" > "${DEIS_LOG_DIR}/all-junit-files.out"
  while read -r file || [[ -n "${file}" ]]
  do
    kubectl exec -c artifacts --namespace=deis workflow-e2e cat "${file}" > "${DEIS_LOG_DIR}/$(basename "$file")"
  done < "${DEIS_LOG_DIR}/all-junit-files.out"
}

get-pod-output-json() {
  local name="${1}"
  kubectl get po "${name}" -a --namespace=deis -o json
}

return-pod-exit-code() {
  local name="${1}"
  wait-for-container-terminated "${name}" "tests"
  exit_code="$(get-pod-output-json "${name}" | jq -r --arg container "tests" ".status.containerStatuses[] | select(.name==\$container) | .state.terminated.exitCode")"

  return "${exit_code}"
}

wait-for-container-terminated() {
  local pod_name="${1}"
  local container_name="${2}"
  local timeout_secs=15
  local increment_secs=1
  local waited_time=0
  local container_status

  while [ ${waited_time} -lt ${timeout_secs} ]; do
    container_status="$(get-pod-output-json "${pod_name}" | jq -r --arg container "${container_name}" ".status.containerStatuses[] | select(.name==\$container) | .state | keys[0]")"

    if [ "${container_status}" == "terminated" ]; then
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += increment_secs ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo
      echo "'${container_name}' container never terminated. Last status was '${container_status}'."
      exit 1
    fi

    echo -n . 1>&2
  done
}
