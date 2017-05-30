VERSION ?= git-$(shell git rev-parse --short HEAD)

SHORT_NAME := e2e-runner
DEIS_REGISTRY ?= quay.io/
IMAGE_PREFIX ?= deisci
IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}
MUTABLE_IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:canary
CLI_VERSION ?= latest
E2E_DIR_LOGS ?= ${PWD}/logs
CLUSTER_DURATION ?= 1600
CLOUD_PROVIDER ?= azure
USE_RBAC ?= false

BATS_CMD := bats --tap tests
SHELLCHECK_CMD := shellcheck -e SC1091 -e SC2002 scripts/*
# -e SC1091 exempts `source relative/path/to/file` errors
# -e SC2002 exempts `Useless cat. Consider 'cmd < file | ..' or 'cmd file | ..' instead.``
TEST_ENV_PREFIX := docker run --rm -v ${CURDIR}:/bash -w /bash quay.io/deis/shell-dev
RUN_PREFIX := docker run -e AUTH_TOKEN="${AUTH_TOKEN}" \
		-e CLAIMER_URL="${CLAIMER_URL}" \
		-e CLI_VERSION="${CLI_VERSION}" \
		-e CLOUD_PROVIDER="${CLOUD_PROVIDER}" \
		-e CLUSTER_DURATION="${CLUSTER_DURATION}" \
		-e CLUSTER_REGEX="${CLUSTER_REGEX}" \
		-e CLUSTER_VERSION="${CLUSTER_VERSION}" \
		-e HELM_VERSION="${HELM_VERSION}" \
		-e JOB_NAME="${JOB_NAME}" \
		-e BUILD_NUMBER="${BUILD_NUMBER}" \
		-e USE_RBAC="${USE_RBAC}" \
		-v "${E2E_DIR_LOGS}":/home/jenkins/logs:rw

build: docker-build
push: docker-push
run:
	${RUN_PREFIX} ${IMAGE}
run-upgrade:
	${RUN_PREFIX} \
		-e RUN_E2E="${RUN_E2E}" \
		-e ORIGIN_WORKFLOW_REPO="${ORIGIN_WORKFLOW_REPO}" \
		-e UPGRADE_WORKFLOW_REPO="${UPGRADE_WORKFLOW_REPO}" ${IMAGE} ./run.sh upgrade

docker-build:
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} .
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

docker-push: docker-immutable-push docker-mutable-push

docker-immutable-push:
	docker push ${IMAGE}

docker-mutable-push:
	docker push ${MUTABLE_IMAGE}

image:
	export E2E_RUNNER_IMAGE=${IMAGE}

test:
	${TEST_ENV_PREFIX} ${SHELLCHECK_CMD}
	${TEST_ENV_PREFIX} ${BATS_CMD}

.PHONY: docker-build docker-push docker-immutable-push docker-mutable-push image test
