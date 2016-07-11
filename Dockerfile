FROM quay.io/deis/base:0.2.0

ENV CLUSTER_DURATION=1600
ENV KUBECONFIG=/home/jenkins/kubeconfig.yaml
ENV GINKGO_NODES=30
ENV HELMC_HOME=/home/jenkins/.helmc

# Install system deps
RUN apt-get update -y && \
    apt-get install -y unzip git

RUN addgroup --gid 999 jenkins
RUN adduser --system \
	--shell /bin/bash \
	--disabled-password \
	--home /app \
  --gid 999 \
  --uid 999 \
	jenkins

RUN curl -s https://get.helm.sh | bash && \
    mv helmc /usr/bin

RUN curl -Ls https://storage.googleapis.com/k8s-claimer/git-8f0ddfd/k8s-claimer-git-8f0ddfd-linux-amd64 \
      > /usr/bin/k8s-claimer && \
    chmod +x /usr/bin/k8s-claimer

RUN curl -Ls https://storage.googleapis.com/kubernetes-release/release/v1.2.4/bin/linux/amd64/kubectl \
      > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

RUN curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
      > /usr/bin/jq && \
    chmod +x /usr/bin/jq

COPY scripts/ /home/jenkins/
RUN mkdir -p /home/jenkins/logs
RUN chown -R jenkins:jenkins /home/jenkins/

USER jenkins
WORKDIR /home/jenkins

ENTRYPOINT ./run.sh
