#!/bin/bash

function check-vars {
  components_to_check=("$@")
  for component in "${components_to_check[@]}"
  do
    actual_sha="${component}_SHA"
    actual_tag="${component}_GIT_TAG"

    if [ -n "${!actual_sha}" ]; then
      export "${component}_GIT_TAG"="git-${!actual_sha:0:7}"
      echo "Setting ${component}_GIT_TAG to ${!actual_tag}"
    fi
  done
}
