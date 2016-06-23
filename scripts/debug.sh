#!/bin/bash

function print-out-running-images {
  echo "Running the following Images:"
  if [ -s "${DEIS_DESCRIBE}" ]; then
    echo "${DEIS_DESCRIBE}" | grep Image:
  fi
}
