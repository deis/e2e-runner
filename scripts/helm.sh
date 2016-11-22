#!/bin/bash

# install the kubernetes helm binary.
install_helm() {
  local helm_version=${HELM_VERSION:-canary}
  local url=https://storage.googleapis.com/kubernetes-helm/helm-"${helm_version}"-linux-amd64.tar.gz
  # Download CLI, retry up to 5 times with 10 second delay between each
  echo "Installing Helm CLI version '${helm_version}' via url '${url}'"
  curl -f --silent --show-error --retry 5 --retry-delay 10 -O "${url}"
  tar -zxvf helm-"${helm_version}"-linux-amd64.tar.gz
  export PATH="linux-amd64:${PATH}"
  export HELM_HOME=/home/jenkins/workspace/$JOB_NAME/$BUILD_NUMBER

  echo "Uninstall tiller-deploy if exists"
  kubectl delete deployment "tiller-deploy" --namespace "kube-system" &> /dev/null || true

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

# get-chart-repo simply returns '<chart>-<repo_type>', stripping `-production` if
# repo_type is 'production'
function get-chart-repo {
  chart="${1}"
  repo_type="${2}"

  echo "${chart}-${repo_type}" | sed -e 's/-production//g'
}

# set-chart-version constructs a version flag for use on helm install, depending
# on the presence of the appropriate env var (supports workflow and workflow-e2e)
function set-chart-version {
  local chart="${1}"

  local version_to_set
  case "${chart}" in
    'workflow')
      version_to_set="${WORKFLOW_TAG}"
      ;;
    'workflow-e2e')
      version_to_set="${WORKFLOW_E2E_TAG}"
      ;;
  esac

  if [ -n "${version_to_set}" ]; then
    echo "Installing ${chart} chart ${chart}-${version_to_set}" >&2
    echo "--version ${version_to_set}"
  fi
}

# set-chart-values constructs a list of chart values to set based on the presence
# of <COMPONENT>_SHA env vars.  The resulting values_to_set can then be used
# when installing the chart provided as the argument (supports workflow and
# workflow-e2e).
function set-chart-values {
  local chart="${1}"

  declare -A component_to_chart_map
  case "${chart}" in
    'workflow')
      component_to_chart_map=(
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
    ;;

    'workflow-e2e')
      component_to_chart_map=(["WORKFLOW_E2E"]="workflow-e2e")
    ;;
  esac

  local values_to_set
  for component in "${!component_to_chart_map[@]}"
  do
    env_var_key="${component}_SHA"
    env_var_value="${!env_var_key}"

    if [ -n "${env_var_value}" ]; then
      component_chart="${component_to_chart_map[${component}]}"
      value_to_set="docker_tag=git-${env_var_value:0:7}"

      if [ "${component_chart}" != "workflow-e2e" ]; then
        value_to_set="${component_chart}.${value_to_set}"
      fi

      if [ -z "${values_to_set}" ]; then
        values_to_set="${value_to_set}"
      else
        values_to_set="${values_to_set},${value_to_set}"
      fi
    fi
  done

  if [ -n "${values_to_set}" ]; then
    echo "--set ${values_to_set}"
  fi
}
