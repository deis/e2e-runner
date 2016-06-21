VERSION ?= git-$(shell git rev-parse --short HEAD)

SHORT_NAME := e2e-runner
DEIS_REGISTRY ?= quay.io/
IMAGE_PREFIX ?= deisci
IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}
MUTABLE_IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:canary

docker-build:
	docker build -t ${IMAGE} .
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

docker-push: docker-immutable-push docker-mutable-push

docker-immutable-push:
	docker push ${IMAGE}

docker-mutable-push:
	docker push ${MUTABLE_IMAGE}

image:
	export E2E_RUNNER_IMAGE=${IMAGE}

test:
	bats tests/
