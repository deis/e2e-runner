#!/bin/bash

# Check to see if deis is installed, if so uninstall it.
clean_cluster() {
  kubectl get pods --namespace=deis | grep -q deis-controller
  if [ $? -eq 0 ]; then
    echo "Deis was installed so I'm removing it!"
    kubectl delete namespace "deis" &> /dev/null

    local timeout_secs=${DEFAULT_TIMEOUT_SECS:-180}
    local increment_secs=1
    local waited_time=0

    echo "Waiting for namespace to go away!"
    while [ ${waited_time} -lt "${timeout_secs}" ]; do
      kubectl get ns | grep -q deis
      if [ $? -gt 0 ]; then
        echo
        return 0
      fi

      sleep ${increment_secs}
      (( waited_time += increment_secs ))

      if [ ${waited_time} -ge "${timeout_secs}" ]; then
        echo "Namespace was never deleted"
        delete-lease
        exit 1
      fi
      echo -n . 1>&2
    done
  elif [ $? -eq 1 ]; then
    echo "Cluster already clean."
    return 0
  fi
}

# install the kubernetes helm binary.
install_helm() {
  local helm_version=${HELM_VERSION:-canary}
  local url=https://storage.googleapis.com/kubernetes-helm/helm-"${helm_version}"-linux-amd64.tar.gz
  # Download CLI, retry up to 5 times with 10 second delay between each
  echo "Installing Helm CLI version '${helm_version}' via url '${url}'"
  curl -f --silent --show-error --retry 5 --retry-delay 10 -O "${url}"
  tar -zxvf helm-"${HELM_VERSION}"-linux-amd64.tar.gz
  export PATH="linux-amd64:${PATH}"
  export HELM_HOME=/home/jenkins/workspace/$JOB_NAME/$BUILD_NUMBER
  helm init
  wait-for-tiller-pod-ready "tiller-deploy"
}

wait-for-tiller-pod-ready() {
  local name="${1}"
  local timeout_secs=60
  local increment_secs=1
  local waited_time=0

  while [ ${waited_time} -lt ${timeout_secs} ]; do
    tiller_replicas="$(kubectl get deployment "${name}" -o 'go-template={{.status.availableReplicas}}' --namespace kube-system)"

    if [ "${tiller_replicas}" == "1" ]; then
      return 0
    fi

    sleep ${increment_secs}
    (( waited_time += increment_secs ))

    if [ ${waited_time} -ge ${timeout_secs} ]; then
      echo
      echo "${name} was never ready."
      delete-lease
      exit 1
    fi

    echo -n . 1>&2
  done
}
