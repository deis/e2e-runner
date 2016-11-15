#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=scripts/functions.sh
. "${DIR}/functions.sh"

export LEASE_RETRIES="${LEASE_RETRIES:-5}"
export HELM_REMOTE_REPO="${HELM_REMOTE_REPO:-https://github.com/deis/charts.git}"
export DEIS_CHART_HOME=$HELMC_HOME/cache/deis
export WORKFLOW_BRANCH="${WORKFLOW_BRANCH:-master}"
export WORKFLOW_E2E_BRANCH="${WORKFLOW_E2E_BRANCH:-master}"
export WORKFLOW_CHART="${WORKFLOW_CHART:-workflow-dev}"
export WORKFLOW_E2E_CHART="${WORKFLOW_E2E_CHART:-workflow-dev-e2e}"
export CHART_REPO_TYPE="${CHART_REPO_TYPE:-dev}"
export DEIS_LOG_DIR="${DEIS_LOG_DIR:-/home/jenkins/logs}"
export K8S_EVENT_LOG="${DEIS_LOG_DIR}/k8s-events.log"
export K8S_OBJECT_LOG="${DEIS_LOG_DIR}/k8s-objects.log"
export DEIS_DESCRIBE="${DEIS_LOG_DIR}/deis-describe.log"
export CLAIMER_URL="${CLAIMER_URL:-k8s-claimer.champagne.deis.com}"

# Make sure we get the env vars for the components setup
components=(
  "BUILDER"
  "CHARTS"
  "CONTROLLER"
  "DOCKERBUILDER"
  "FLUENTD"
  "LOGGER"
  "MINIO"
  "MONITOR"
  "NSQ"
  "POSTGRES"
  "REDIS"
  "REGISTRY"
  "REGISTRY_PROXY"
  "ROUTER"
  "SLUGBUILDER"
  "SLUGRUNNER"
  "WORKFLOW_CLI"
  "WORKFLOW_E2E"
  "WORKFLOW_MANAGER"
)

check-vars "${components[@]}"
