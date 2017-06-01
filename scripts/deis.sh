#!/bin/bash

# dump-logs dumps logs from all k8s resources in the deis namespace to a file
# as well as printing out the image running in each pod
dump-logs() {
  echo "Running kubectl describe pods and piping the output to ${DEIS_DESCRIBE}"
  kubectl describe ns,svc,pods,rc,daemonsets --namespace=deis > "${DEIS_DESCRIBE}" 2> /dev/null
  print-out-running-images
}

get-router-ip() {
  command_output="$(kubectl --namespace=deis get svc deis-router -o json | jq -r ".status.loadBalancer.ingress[0].ip")"
  if [ ! -z "${command_output}" ] && [ "${command_output}" != "null" ]; then
    echo "${command_output}"
  fi
}

# Check to see if deis is installed, if so uninstall it.
clean_cluster() {
  if kubectl get ns | grep -q deis; then
    echo "Deis was installed so I'm removing it!"
    kubectl delete ns "deis" &> /dev/null

    local timeout_secs=${DEFAULT_TIMEOUT_SECS:-180}
    local increment_secs=1
    local waited_time=0

    echo "Waiting for namespace to go away!"
    while [ ${waited_time} -lt "${timeout_secs}" ]; do
      if ! kubectl get ns | grep -q deis; then
        echo
        return 0
      fi

      sleep ${increment_secs}
      (( waited_time += increment_secs ))

      if [ ${waited_time} -ge "${timeout_secs}" ]; then
        echo "Namespace was never deleted"
        exit 1
      fi
      echo -n . 1>&2
    done
  elif [ $? -eq 1 ]; then
    echo "Cluster already clean."
    return 0
  fi
}

get-pod-logs() {
  pods=$(kubectl get pods --all-namespaces | sed '1d' | awk '{print $1, $2}')
  while read -r namespace pod; do
    kubectl logs "${pod}" --namespace="${namespace}" >> "${DEIS_LOG_DIR}/${namespace}-${pod}.log"
    kubectl logs "${pod}" -p --namespace="${namespace}" >> "${DEIS_LOG_DIR}/${namespace}-${pod}-previous.log"
  done <<< "$pods"
}

download-deis-cli() {
  local version="${1:-latest}"

  # try multiple buckets for specific cli version
  curl-cli-from-gcs-bucket "${version}" "workflow-cli-master" || \
  curl-cli-from-gcs-bucket "${version}" "workflow-cli-pr" || \
  curl-cli-from-gcs-bucket "${version}" "workflow-cli-release"
  chmod +x deis
  export PATH="${PWD}:${PATH}"
}

function curl-cli-from-gcs-bucket() {
  local version="${1}"
  local gcs_bucket="${2}"
  local base_url="https://storage.googleapis.com/${gcs_bucket}"
  local url

  case "${version}" in
    "latest" | "stable")
      url="${base_url}"
      ;;
    *)
      url="${base_url}/${version}"
      ;;
  esac
  url="${url}/deis-${version}-linux-amd64"

  # Download CLI, retry up to 5 times with 10 second delay between each
  echo "Installing Workflow CLI version '${version}' via url '${url}'"
  curl -f -sSL --show-error -I "${url}"
  curl -f -sSL --show-error --retry 5 --retry-delay 10 -o deis "${url}"
}
