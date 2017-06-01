#!/bin/bash

# Add workflow chart repo and install chart
chart_repo="$(get-chart-repo workflow "${CHART_REPO_TYPE}")"
echo "Adding workflow chart repo '${chart_repo}'"
helm repo add "${chart_repo}" https://charts.deis.com/"${chart_repo}"

install_cmd="helm install --wait --devel ${chart_repo}/workflow --namespace=deis \
$(set-chart-version workflow) $(set-chart-values workflow)"
# execute in subshell to print full command being run
if ! (set -x; eval "${install_cmd}"); then
  exit 1
fi

dump-logs

# Add workflow-e2e chart repo and install chart
chart_repo="$(get-chart-repo workflow-e2e "${CHART_REPO_TYPE}")"
echo "Adding workflow-e2e chart repo '${chart_repo}'"
helm repo add "${chart_repo}" https://charts.deis.com/"${chart_repo}"

install_cmd="helm install --wait --devel ${chart_repo}/workflow-e2e --namespace=deis \
$(set-chart-version workflow-e2e) $(set-chart-values workflow-e2e)"
# execute in subshell to print full command being run
if ! (set -x; eval "${install_cmd}"); then
  exit 1
fi

echo "Running kubectl describe pod workflow-e2e and piping the output to ${DEIS_DESCRIBE}"
kubectl describe pod workflow-e2e --namespace=deis >> "${DEIS_DESCRIBE}" 2> /dev/null

# Capture e2e run test output
tail_logs_from_e2e_pod
podExitCode=$?
echo "Test pod exited with code:${podExitCode}"

# Collect artifacts
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
