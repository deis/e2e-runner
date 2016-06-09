#!/bin/bash

deis_healthcheck() {
  wait-for-all-pods "deis"
  local successes
  echo "Checking to see if the workflow has come up properly."
  while [[ ${successes} -lt 10 ]]; do
    wait-for-router
    let successes+=1
    if ! ((successes % 10)); then
      echo "Successfully interacted with Deis platform ${successes} time(s)."
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
    (( waited_time += ${increment_secs} ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo "Not all pods started."
      kubectl get pods --namespace="${name}"
      delete_lease
      exit 1
    fi

    echo -n . 1>&2
  done
}

get-router-ip() {
  local ip="null"
  command_output="$(kubectl --namespace=deis get svc deis-router -o json | jq -r ".status.loadBalancer.ingress[0].ip")"
  if [ ! -z ${command_output} ] && [ ${command_output} != "null" ]; then
    echo "${command_output}"
  fi
}

wait-for-router() {
  local timeout_secs=30
  local increment_secs=1
  local waited_time=0
  local command_output

  while [ ${waited_time} -lt ${timeout_secs} ]; do
    local router_ip=get-router-ip
    command_output="$(curl -sSL -o /dev/null -w '%{http_code}' "http://deis.$(get-router-ip).nip.io/v2/")"
    if [ "${command_output}" == "401" ]; then
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += ${increment_secs} ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo "Endpoint is unresponsive at ${url}"
      delete_lease
      exit 1
    fi

    echo -n . 1>&2
  done
}

get-pod-logs() {
  pods=$(kubectl get pods --namespace=deis | sed '1d' | awk '{print $1}')
  while read -r pod; do
    kubectl logs "${pod}" --namespace=deis >> "${DEIS_LOG_DIR}/${pod}.log"
    kubectl logs "${pod}" -p --namespace=deis >> "${DEIS_LOG_DIR}/${pod}-previous.log"
  done <<< "$pods"
}
