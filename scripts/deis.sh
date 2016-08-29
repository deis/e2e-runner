#!/bin/bash

deis_healthcheck() {
  wait-for-all-pods "deis"
  local successes=0
  local failures=0
  local max_attempts=10
  echo "Checking to see if the workflow has come up properly."
  while [[ ${successes} -lt "${max_attempts}" ]] && [[ ${failures} -lt "${max_attempts}" ]]; do
    wait-for-router
    if [ $? -eq 0 ]; then
      let successes+=1
    else
      let failures+=1
    fi

    if [ ${successes} -eq ${max_attempts} ]; then
      echo "Successfully interacted with Deis platform via '$(get-router-ip)' ${successes} time(s)."
    elif [ ${failures} -eq ${max_attempts} ]; then
      echo "Failed to interact with Deis platform via '$(get-router-ip)' ${failures} time(s); deleting lease and exiting."
      delete-lease
      exit 1
    fi
    sleep 1
  done
}

wait-for-all-pods() {
  echo "Waiting for all pods to be running"

  local timeout_secs=180
  local increment_secs=1
  local waited_time=0

  local command_output
  while [ ${waited_time} -lt ${timeout_secs} ]; do
    kubectl get pods --namespace=deis -o json | jq -r ".items[].status.conditions[0].status" | grep -q "False"
    if [ $? -gt 0 ]; then
      echo
      echo "All pods are running!"
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += increment_secs ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo "Not all pods started."
      kubectl get pods --namespace=deis
      delete-lease
      exit 1
    fi

    echo -n . 1>&2
  done
}

get-router-ip() {
  command_output="$(kubectl --namespace=deis get svc deis-router -o json | jq -r ".status.loadBalancer.ingress[0].ip")"
  if [ ! -z "${command_output}" ] && [ "${command_output}" != "null" ]; then
    echo "${command_output}"
  fi
}

wait-for-router() {
  local timeout_secs=30
  local increment_secs=1
  local waited_time=0
  local command_output

  while [ ${waited_time} -lt ${timeout_secs} ]; do
    router_ip="$(get-router-ip)"

    command_output="$(curl -sSL -o /dev/null -w '%{http_code}' "${router_ip}")"
    command_exit_code=$?

    if [ "${command_output}" == "404" ]; then
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += increment_secs ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo "Endpoint is unresponsive at ${router_ip}"
      delete-lease
      exit 1
    fi

    echo -n . 1>&2
    return ${command_exit_code}
  done
}

get-pod-logs() {
  pods=$(kubectl get pods --namespace=deis | sed '1d' | awk '{print $1}')
  while read -r pod; do
    kubectl logs "${pod}" --namespace=deis >> "${DEIS_LOG_DIR}/${pod}.log"
    kubectl logs "${pod}" -p --namespace=deis >> "${DEIS_LOG_DIR}/${pod}-previous.log"
  done <<< "$pods"
}
