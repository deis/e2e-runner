#!/bin/bash

# helmc-remove (entire file)
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
