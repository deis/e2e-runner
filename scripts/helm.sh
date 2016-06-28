#!/bin/bash

# Check to see if deis is installed, if so uninstall it.
clean_cluster() {
  kubectl get pods --namespace=deis | grep deis-controller
  if [ $? -eq 0 ]; then
    echo "Deis was installed so I'm removing it!"
    kubectl delete namespace "deis" &> /dev/null

    local timeout_secs=${DEFAULT_TIMEOUT_SECS:-180}
    local increment_secs=1
    local waited_time=0

    echo "Waiting for namespace to go away!"
    while [ ${waited_time} -lt ${timeout_secs} ]; do
      kubectl get ns | grep deis
      if [ $? -gt 0 ]; then
        echo
        return 0
      fi

      sleep ${increment_secs}
      (( waited_time += increment_secs ))

      if [ ${waited_time} -ge ${timeout_secs} ]; then
        echo "Namespace was never deleted"
        delete_lease
        exit 1
      fi
      echo -n . 1>&2
    done
  elif [ $? -eq 1 ]; then
    echo "Cluster already clean."
    return 0
  fi
}
