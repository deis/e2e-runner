#!/bin/bash

function check-vars {
  repos="${1}"

  for repo in "${repos[@]}"
  do
    actual_sha="${repo}_SHA"
    actual_tag="${repo}_GIT_TAG"

    if [ -n "${!actual_sha}" ]; then
      export "${repo}"_GIT_TAG=git-"${!actual_sha:0:7}"
      echo "Setting ${repo}_GIT_TAG to ${!actual_tag}"
    fi
  done
}

function get-chart-repo {
  chart="${1}"
  repo_type="${2}"

  # strip '-production' if repo_type 'production'
  echo "${chart}-${repo_type}" | sed -e 's/-production//g'
}

function set-chart-values-from-env {
  local values_to_set

  declare -A component_to_chart_map
  component_to_chart_map+=(
    ["BUILDER"]="builder"
    ["CONTROLLER"]="controller"
    ["DOCKERBUILDER"]="dockerbuilder"
    ["FLUENTD"]="fluentd"
    ["LOGGER"]="logger"
    ["MINIO"]="minio"
    ["MONITOR"]="monitor"
    ["NSQ"]="nsqd"
    ["POSTGRES"]="database"
    ["REDIS"]="redis"
    ["REGISTRY"]="registry"
    ["REGISTRY_PROXY"]="registry-proxy"
    ["REGISTRY_TOKEN_REFRESHER"]="registry-token-refresher"
    ["ROUTER"]="router"
    ["SLUGBUILDER"]="slugbuilder"
    ["SLUGRUNNER"]="slugrunner"
    ["WORKFLOW_MANAGER"]="workflow-manager"
  )

  for component in "${!component_to_chart_map[@]}"
  do
    actual_tag="${component}_GIT_TAG"

    # if <COMPONENT>_GIT_TAG is set to a non-null/non-empty value
    if [ -n "${!actual_tag}" ]; then
      component_chart="${component_to_chart_map[${component}]}"
      value_to_set="${component_chart}.docker_tag=${!actual_tag}"

      if [ -z "${values_to_set}" ]; then
        values_to_set="${value_to_set}"
      else
        values_to_set="${values_to_set},${value_to_set}"
      fi
    fi
  done

  echo "${values_to_set}"
}
