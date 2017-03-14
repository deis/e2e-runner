#!/bin/bash

# Upgrade-specific config
export ORIGIN_WORKFLOW_REPO="${ORIGIN_WORKFLOW_REPO:-workflow}"
export UPGRADE_WORKFLOW_REPO="${UPGRADE_WORKFLOW_REPO:-workflow-staging}"

# Add workflow chart repos
chart_repos="${ORIGIN_WORKFLOW_REPO} ${UPGRADE_WORKFLOW_REPO}"
for chart_repo in ${chart_repos}; do
  echo "Adding workflow chart repo '${chart_repo}'"
  helm repo add "${chart_repo}" https://charts.deis.com/"${chart_repo}"
done

install_cmd="helm install --wait ${ORIGIN_WORKFLOW_REPO}/workflow --namespace=deis \
$(set-chart-version workflow) $(set-chart-values workflow)"
# execute in subshell to print full command being run
(set -x; eval "${install_cmd}")

# get release name
release="$(helm ls --date --short | tail -n 1)"
helm ls "${release}"

dump-logs

# if off-cluster storage, create state
if [ "${STORAGE_TYPE}" != "" ]; then
  username='testuser'
  password="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16 ;)"
  email="${username}@example.com"

  download-deis-cli
  deis version

  deis register deis."$(get-router-ip)".nip.io \
    --username="${username}" --password="${password}" --email="${email}"

  app="${username}-app"
  deis create "${app}" --no-remote
  deis pull deis/example-go -a "${app}"

  if [[ $? -ne 0 ]]; then
    exit $?
  fi
fi

# Upgrade release
upgrade_cmd="helm upgrade --wait ${release} ${UPGRADE_WORKFLOW_REPO}/workflow \
--set controller.registration_mode=enabled $(set-chart-values workflow)"
# TODO: remove this "registration_mode" override when e2e tests expect "admin_only" as the default
# execute in subshell to print full command being run
(set -x; eval "${upgrade_cmd}")

helm ls "${release}"

dump-logs

# Sanity check
kubectl get po --namespace deis

# if off-cluster storage, check state
if [ "${STORAGE_TYPE}" != "" ]; then
  deis login deis."$(get-router-ip)".nip.io \
    --username="${username}" --password="${password}"

  deis apps:info -a "${app}"
  deis apps:destroy -a "${app}" --confirm "${app}"
  deis auth:cancel --username="${username}" --password="${password}" --yes

  if [[ $? -ne 0 ]]; then
    exit $?
  fi
fi

if [ "${RUN_E2E}" == true ]; then
  # Add workflow-e2e chart repo and install chart
  chart_repo="$(get-chart-repo workflow-e2e "${CHART_REPO_TYPE}")"
  echo "Adding workflow-e2e chart repo '${chart_repo}'"
  helm repo add "${chart_repo}" https://charts.deis.com/"${chart_repo}"

  # shellcheck disable=SC2046
  helm install --wait "${chart_repo}"/workflow-e2e --namespace=deis \
    $(set-chart-version workflow-e2e) $(set-chart-values workflow-e2e)

  echo "Running kubectl describe pod workflow-e2e and piping the output to ${DEIS_DESCRIBE}"
  kubectl describe pod workflow-e2e --namespace=deis >> "${DEIS_DESCRIBE}" 2> /dev/null

  # Capture e2e run test output
  tail_logs_from_e2e_pod
  podExitCode=$?
  echo "Test pod exited with code:${podExitCode}"

  #Collect artifacts
  retrive-artifacts
  retrieveArtifactsExitCode=$?
  echo "Retrieving artifacts exited with code:${retrieveArtifactsExitCode}"

  if [ "$podExitCode" -ne "0" ]; then
    echo "Received a non-zero exit code from the e2e test pod..."
    exit ${podExitCode}
  fi

  if [ "$retrieveArtifactsExitCode" -ne "0" ]; then
    echo "Received a non-zero exit code when trying to fetch artifacts..."
    exit ${retrieveArtifactsExitCode}
  fi
fi
