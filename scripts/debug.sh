#!/bin/bash

function print-out-running-images {
  echo "Running the following Images:"
  if [ -s "${DEIS_DESCRIBE}" ]; then
    cat "${DEIS_DESCRIBE}" | grep Image:
  fi
}
