VERSION ?= git-$(shell git rev-parse --short HEAD)

SHORT_NAME := e2e-runner
DEIS_REGISTRY ?= quay.io/
IMAGE_PREFIX ?= deisci
IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}
MUTABLE_IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:canary
CLI_VERSION ?= latest
E2E_DIR_LOGS ?= ${PWD}/logs
CLUSTER_DURATION ?= 1600

BATS_CMD := bats --tap tests
SHELLCHECK_CMD := shellcheck -e SC1091 -e SC2002 scripts/*
# -e SC1091 exempts `source relative/path/to/file` errors
# -e SC2002 exempts `Useless cat. Consider 'cmd < file | ..' or 'cmd file | ..' instead.``
TEST_ENV_PREFIX := docker run --rm -v ${CURDIR}:/bash -w /bash quay.io/deis/shell-dev

build: docker-build
push: docker-push
run:
	docker run -e AUTH_TOKEN="${AUTH_TOKEN}" \
		-e CLI_VERSION="${CLI_VERSION}" \
		-e CLUSTER_DURATION="${CLUSTER_DURATION}" \
		-e CLUSTER_REGEX="${CLUSTER_REGEX}" \
		-e CLUSTER_VERSION="${CLUSTER_VERSION}" \
		-v "${E2E_DIR_LOGS}":/home/jenkins/logs:rw ${IMAGE}

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
	${SHELLCHECK_CMD}
	${BATS_CMD}

docker-test:
	${TEST_ENV_PREFIX} ${SHELLCHECK_CMD}
	${TEST_ENV_PREFIX} ${BATS_CMD}


.PHONY: docker-build docker-push docker-immutable-push docker-mutable-push image test docker-test
