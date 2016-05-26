#!/bin/bash

export HELM_REMOTE_REPO="${HELM_REMOTE_REPO:-https://github.com/deis/charts.git}"
export DEIS_CHART_HOME=$HELMC_HOME/cache/deis
export WORKFLOW_BRANCH="${WORKFLOW_BRANCH:-master}"
export WORKFLOW_E2E_BRANCH="${WORKFLOW_E2E_BRANCH:-master}"
export WORKFLOW_CHART="${WORKFLOW_CHART:-workflow-dev}"
export WORKFLOW_E2E_CHART="${WORKFLOW_E2E_CHART:-workflow-dev-e2e}"
export DEIS_LOG_DIR="${DEIS_LOG_DIR:-/home/jenkins/logs}"
export K8S_EVENT_LOG="${DEIS_LOG_DIR}/k8s-events.log"
export K8S_OBJECT_LOG="${DEIS_LOG_DIR}/k8s-objects.log"
export DEIS_DESCRIBE="${DEIS_LOG_DIR}/deis-describe.log"

# Make sure we get the env vars for the components setup
if [ -n "${BUILDER_SHA}" ]; then
  export "BUILDER_GIT_TAG"="git-${BUILDER_SHA:0:7}"
  echo "Setting BUILDER_GIT_TAG to ${BUILDER_GIT_TAG}"
fi

if [ -n "${CONTROLLER_SHA}" ]; then
  export "CONTROLLER_GIT_TAG"="git-${CONTROLLER_SHA:0:7}"
  echo "Setting CONTROLLER_GIT_TAG to ${CONTROLLER_GIT_TAG}"
fi

if [ -n "${DOCKERBUILDER_SHA}" ]; then
  export "DOCKERBUILDER_GIT_TAG"="git-${DOCKERBUILDER_SHA:0:7}"
  echo "Setting DOCKERBUILDER_GIT_TAG to ${DOCKERBUILDER_GIT_TAG}"
fi

if [ -n "${FLUENTD_SHA}" ]; then
  export "FLUENTD_GIT_TAG"="git-${FLUENTD_SHA:0:7}"
  echo "Setting FLUENTD_GIT_TAG to ${FLUENTD_GIT_TAG}"
fi

if [ -n "${LOGGER_SHA}" ]; then
  export "LOGGER_GIT_TAG"="git-${LOGGER_SHA:0:7}"
  echo "Setting LOGGER_GIT_TAG to ${LOGGER_GIT_TAG}"
fi

if [ -n "${MINIO_SHA}" ]; then
  export "MINIO_GIT_TAG"="git-${MINIO_SHA:0:7}"
  echo "Setting MINIO_GIT_TAG to ${MINIO_GIT_TAG}"
fi

if [ -n "${POSTGRES_SHA}" ]; then
  export "POSTGRES_GIT_TAG"="git-${POSTGRES_SHA:0:7}"
  echo "Setting POSTGRES_GIT_TAG to ${POSTGRES_GIT_TAG}"
fi

if [ -n "${REGISTRY_SHA}" ]; then
  export "REGISTRY_GIT_TAG"="git-${REGISTRY_SHA:0:7}"
  echo "Setting REGISTRY_GIT_TAG to ${REGISTRY_GIT_TAG}"
fi

if [ -n "$ROUTER_SHA" ]; then
  export "ROUTER_GIT_TAG"="git-${ROUTER_SHA:0:7}"
  echo "Setting ROUTER_GIT_TAG to ${ROUTER_GIT_TAG}"
fi

if [ -n "${SLUGBUILDER_SHA}" ]; then
  export "SLUGBUILDER_GIT_TAG"="git-${SLUGBUILDER_SHA:0:7}"
  echo "Setting SLUGBUILDER_GIT_TAG to ${SLUGBUILDER_GIT_TAG}"
fi

if [ -n "${SLUGRUNNER_SHA}" ]; then
  export "SLUGRUNNER_GIT_TAG"="git-${SLUGRUNNER_SHA:0:7}"
  echo "Setting SLUGRUNNER_GIT_TAG to ${SLUGRUNNER_GIT_TAG}"
fi

if [ -n "${WORKFLOW_E2E_SHA}" ]; then
  export "WORKFLOW_E2E_GIT_TAG"="git-${WORKFLOW_E2E_SHA:0:7}"
  echo "Setting WORKFLOW_E2E_GIT_TAG to ${WORKFLOW_E2E_GIT_TAG}"
fi
