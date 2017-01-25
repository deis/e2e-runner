#!/bin/bash

source ./config.sh
source ./debug.sh
source ./deis.sh
source ./e2e.sh
source ./helm.sh
source ./lease.sh

if [ ! -d "${DEIS_LOG_DIR}" ]; then
  mkdir -p "${DEIS_LOG_DIR}"
fi

# Get a k8s cluster lease
lease

# Get node information
kubectl get nodes

# Clean cluster if needed
echo "Cleaning cluster if needed"
clean_cluster

echo "Installing kubernetes helm"
install_helm

case "${1}" in
  'upgrade')
    source ./run_upgrade.sh
    ;;
  *)
    source ./run_e2e.sh
    ;;
esac

# Clean up
delete-lease
deleteLeaseExitCode=$?
echo "Deleting lease exited with code:${deleteLeaseExitCode}"

if [ "$deleteLeaseExitCode" -ne "0" ]; then
  echo "Deleting the lease returned a non-zero exit code..."
  exit ${deleteLeaseExitCode}
fi

exit 0
