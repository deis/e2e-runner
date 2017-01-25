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

echo "Installing Workflow chart from the '${ORIGIN_WORKFLOW_REPO}' chart repo..."
# shellcheck disable=SC2046
helm install "${ORIGIN_WORKFLOW_REPO}"/workflow --namespace=deis \
  $(set-chart-version workflow) $(set-chart-values workflow)
release="$(helm ls --date --short | tail -n 1)"
helm ls "${release}"

dump-logs && deis-healthcheck

# Upgrade release
echo "Upgrading release ${release} using the latest chart from the '${UPGRADE_WORKFLOW_REPO}' chart repo."
# shellcheck disable=SC2046
helm upgrade "${release}" "${UPGRADE_WORKFLOW_REPO}"/workflow $(set-chart-values workflow)
helm ls "${release}"

dump-logs && deis-healthcheck

# Sanity check
kubectl get po --namespace deis

if [ "${RUN_E2E}" == true ]; then
  # Add workflow-e2e chart repo and install chart
  chart_repo="$(get-chart-repo workflow-e2e "${CHART_REPO_TYPE}")"
  echo "Adding workflow-e2e chart repo '${chart_repo}'"
  helm repo add "${chart_repo}" https://charts.deis.com/"${chart_repo}"

  # shellcheck disable=SC2046
  helm install "${chart_repo}"/workflow-e2e --namespace=deis \
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
