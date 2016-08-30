FROM quay.io/deis/base:0.3.0

ENV CLUSTER_DURATION=1600 \
	KUBECONFIG=/home/jenkins/kubeconfig.yaml \
	GINKGO_NODES=30 \
	HELMC_HOME=/home/jenkins/.helmc \
	K8S_VERSION=1.3.5

RUN addgroup --gid 999 jenkins && \
	adduser --system \
		--shell /bin/bash \
		--disabled-password \
		--home /app \
		--gid 999 \
		--uid 999 \
		jenkins

COPY scripts/ /home/jenkins/

RUN apt-get update -y && \
	apt-get install -y \
		git \
		unzip && \
	curl -s https://get.helm.sh | bash && \
	mv helmc /usr/bin && \
	curl -Ls -o /usr/bin/k8s-claimer https://storage.googleapis.com/k8s-claimer/git-8669f8a/k8s-claimer-git-8669f8a-linux-amd64 && \
	chmod +x /usr/bin/k8s-claimer && \
	curl -Ls -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v$K8S_VERSION/bin/linux/amd64/kubectl && \
	chmod +x /usr/bin/kubectl && \
	curl -Ls -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
	chmod +x /usr/bin/jq && \
	mkdir -p /home/jenkins/logs && \
	chown -R jenkins:jenkins /home/jenkins/ && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc

USER jenkins
WORKDIR /home/jenkins

CMD ["./run.sh"]
