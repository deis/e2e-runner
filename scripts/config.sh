#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=scripts/functions.sh
. "${DIR}/functions.sh"

export LEASE_RETRIES="${LEASE_RETRIES:-5}"
export CHART_REPO_TYPE="${CHART_REPO_TYPE:-dev}"
export DEIS_LOG_DIR="${DEIS_LOG_DIR:-/home/jenkins/logs}"
export K8S_EVENT_LOG="${DEIS_LOG_DIR}/k8s-events.log"
export K8S_OBJECT_LOG="${DEIS_LOG_DIR}/k8s-objects.log"
export DEIS_DESCRIBE="${DEIS_LOG_DIR}/deis-describe.log"
export CLAIMER_URL="${CLAIMER_URL:-k8s-claimer.champagne.deis.com}"

repos=(
  "BUILDER"
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
  "WORKFLOW_E2E"
  "WORKFLOW_MANAGER"
)

check-vars "${repos[@]}"
