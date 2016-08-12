[![Docker Repository on Quay](https://quay.io/repository/deisci/e2e-runner/status "Docker Repository on Quay")](https://quay.io/repository/deisci/e2e-runner)

# e2e-runner
Docker image for running workflow-e2e

## Overview of use

E2e-runner coordinates the entire e2e run against a Workflow [chart](https://github.com/deis/charts/tree/master/workflow-dev), including:

  1. Coordinating the leasing of a GKE k8s cluster via [k8s-claimer](https://github.com/deis/k8s-claimer),
  2. Cleaning up the leased cluster if need be (primarily deleting the `deis` namespace if still exists),
  3. Setting up the local [helmc](https://github.com/helm/helm-classic) install on the leased cluster,
  4. Generating and installing the Workflow and [Workflow-e2e](https://github.com/deis/charts/tree/master/workflow-dev-e2e) charts,
  5. Monitoring to see when these charts are up and running,
  6. Following and capturing chart logs and placing them where Jenkins/others can find them before deleting the cluster lease and exiting.

See the main [run](https://github.com/deis/e2e-runner/blob/master/scripts/run.sh) script for the basic outline of actions presented above.  It is a good entry point into the finer details of e2e-runner functionality.

## Running the tests on CI
To run the tests for a jenkins job you should have a `docker run` command that looks like the following:

```
env > /home/jenkins/workspace/${JOB_NAME}/${BUILD_NUMBER}/env.file
docker run \
  --env-file=/home/jenkins/workspace/${JOB_NAME}/${BUILD_NUMBER}/env.file \
  -u jenkins:jenkins \
  -v /home/jenkins/workspace/${JOB_NAME}/${BUILD_NUMBER}:/home/jenkins/logs:rw \
  quay.io/deisci/e2e-runner
```

A few different things are happening here. First we export all the local environment variables to a file so we can pass those into the container at runtime. This allows us to use secret text values for things like `$AUTH_TOKEN`. When we call `docker run` we make sure we specify the user `jenkins:jenkins`. This way the container has write permissions into the volume mount.

## Running the tests locally
```
$ docker run -e AUTH_TOKEN=$AUTH_TOKEN quay.io/deisci/e2e-runner
```

## Environment Variables
* `AUTH_TOKEN` - Token needed to talk to [k8s claimer](https://github.com/deis/k8s-claimer)
* `CLUSTER_DURATION` - How long to lease the k8s cluster (default: `800 seconds`)
* `GINKGO_NODES` - How many nodes to use when running e2e tests in parallel (default: `30`)
* `HELM_REMOTE_REPO` - Remote repo to use for fetching charts (default: `https://github.com/deis/charts.git`)
* `WORKFLOW_BRANCH` - Which branch in `deis/charts` to checkout (default: `master`)
* `WORKFLOW_E2E_BRANCH` - Which branch in `deis/charts` to checkout (default: `master`)
* `WORKFLOW_CHART` - Which chart to use for installing [workflow](https:github.com/deis/workflow).
* `WORKFLOW_E2E_CHART` - Which chart to use for installing [workflow-e2e](https:github.com/deis/workflow-e2e).
