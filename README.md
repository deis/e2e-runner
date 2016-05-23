# e2e-runner
Docker image for running workflow-e2e

## Environment Variables

* `CLUSTER_DURATION` - How long to lease the k8s cluster (default: `800 seconds`)
* `GINKGO_NODES` - How many nodes to use when running e2e tests in parallel (default: `30`)
* `WORKFLOW_BRANCH` - Which branch in `deis/charts` to checkout (default: `master`)
* `WORKFLOW_E2E_BRANCH` - Which branch in `deis/charts` to checkout (default: `master`)
* `WORKFLOW_CHART` - Which chart to use for installing [workflow](https:github.com/deis/workflow).
* `WORKFLOW_E2E_CHART` - Which chart to use for installing [workflow-e2e](https:github.com/deis/workflow-e2e).

