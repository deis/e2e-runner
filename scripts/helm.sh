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
      exit 1
    fi

    echo -n . 1>&2
  done
}

# get-chart-repo simply returns '<chart>-<repo_type>', stripping `-production` if
# repo_type is 'production' and stripping '-staging' if chart is not 'workflow'
# (currently supports chart of 'workflow' or 'workflow-e2e')
function get-chart-repo {
  chart="${1}"
  repo_type="${2}"

  chart_repo="$(echo "${chart}-${repo_type}" | sed -e 's/-production//g')"

  if [ "${chart}" == 'workflow-e2e' ]; then
    # only set repo if we are looking for a specific workflow-e2e version
    # else, default to -dev repo
    if [ -n "${WORKFLOW_E2E_TAG}" ]; then
      chart_repo="${chart_repo//-staging/}"
    else
      chart_repo="${chart}-dev"
    fi
  fi

  if [ "${chart}" == 'workflow' ] && [ "${repo_type}" == 'pr' ]; then
    # if repo type is pr but WORKFLOW_TAG is empty (specific chart version not specified)
    # then pull latest from -dev repo for testing docker image PR artifact
    if [ -z "${WORKFLOW_TAG}" ]; then
      chart_repo="${chart}-dev"
    fi
  fi

  echo "${chart_repo}"
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
      component_to_chart_map=(
        ["WORKFLOW_E2E"]="workflow-e2e"
        ["WORKFLOW_CLI"]="workflow-cli"
      )
    ;;
  esac

  local values_to_set
  # Check <COMPONENT>_SHA env vars and set values appropriately
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

      if [ "${env_var_key}" == "WORKFLOW_CLI_SHA" ]; then
        value_to_set="cli_version=${env_var_value:0:7}"
      fi

      values_to_set="$(append-value "${value_to_set}" "${values_to_set}")"
    fi
  done

  # Check STORAGE_TYPE env var for setting up external storage backend
  if [ "${STORAGE_TYPE}" == "s3" ]; then
    for value_pair in global.storage=s3 s3.accesskey=${AWS_ACCESS_KEY} s3.secretkey=${AWS_SECRET_KEY} s3.builder_bucket=${BUILDER_BUCKET} s3.database_bucket=${DATABASE_BUCKET} s3.registry_bucket=${REGISTRY_BUCKET}; do
      values_to_set="$(append-value "${value_pair}" "${values_to_set}")"
    done
  elif [ "${STORAGE_TYPE}" == "gcs" ]; then
    for value_pair in global.storage=gcs gcs.key_json=${GCS_KEY_JSON} gcs.builder_bucket=${BUILDER_BUCKET} gcs.database_bucket=${DATABASE_BUCKET} gcs.registry_bucket=${REGISTRY_BUCKET}; do
      values_to_set="$(append-value "${value_pair}" "${values_to_set}")"
    done
  fi

  if [ "${chart}" == "workflow" ]; then
    values_to_set="$(append-value "global.use_rbac=${USE_RBAC}" "${values_to_set}")"
  fi

  if [ -n "${values_to_set}" ]; then
    echo "--set ${values_to_set}"
  fi
}

function append-value() {
  new_value="${1}"
  values="${2}"

  if [ -z "${values}" ]; then
    values="${new_value}"
  else
    values="${values},${new_value}"
  fi

  echo "${values}"
}
