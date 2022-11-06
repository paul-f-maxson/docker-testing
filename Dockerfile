# syntax=docker/dockerfile:1.4

FROM alpine:latest

ARG SRCDIR=src
ARG CNI_PLUGINS_VERSION=1.1.1
ARG CRICTL_VERSION=1.25.0
ARG KUBEADM_VERSION=1.25.3
ARG KUBELET_SERVICE_VERSION=0.4.0
ARG ALPINE_VERSION_MINOR=3.16
ARG MACMPI_HEADLESS_OVERLAY_BLOB_HASH=9141ed77ee4a6b1784069d245f345dc632825a95
ARG ALPINE_PATCH=2
ARG ALPINE_ARCH=x86_64
ARG K8S_ARCH=amd64
ARG CNI_DEST=/opt/cni/bin
ARG K8S_DEST=/usr/local/bin


# Download the standard alpine iso file. Use pinned version.

ADD https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION_MINOR}/releases/${ALPINE_ARCH}/alpine-standard-${ALPINE_VERSION_MINOR}.${ALPINE_PATCH}-${ALPINE_ARCH}.iso /tmp/alpine.iso

WORKDIR /alpine

RUN apk update \
  && apk add p7zip


# Extract the iso image as files, answering yes to prompts.

RUN 7z x -y /tmp/alpine.iso 


# Download the headless setup overlay file and put it in ./alpine. Use pinned version.

ADD https://github.com/macmpi/alpine-linux-headless-bootstrap/blob/${MACMPI_HEADLESS_OVERLAY_BLOB_HASH}/headless.apkovl.tar.gz .

COPY /${SRCDIR}/* .


# INSTALL K8S ON THE IMAGE
# based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2

WORKDIR /alpine${CNI_DEST}

# Install CNI plugins (required for most pod network):

ADD https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${K8S_ARCH}-v${CNI_PLUGINS_VERSION}.tgz /tmp/cni.tgz

RUN tar --extract --gzip --file=/tmp/cni.tgz


WORKDIR /alpine${K8S_DEST}

# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))

ADD https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${K8S_ARCH}.tar.gz /tmp/crictl.tgz

RUN tar --extract --gzip --file=/tmp/crictl.tgz


# Install kubeadm, kubelet and kubectl

ADD https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubeadm ./kubeadm

ADD https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubelet ./kubelet

RUN chmod +x kubeadm && chmod +x kubelet


# Add a kubelet systemd service

WORKDIR /alpine/etc/systemd/system

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${K8S_DEST}:g" > kubelet.service

RUN mkdir -p kubelet.service.d

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${K8S_DEST}:g" > kubelet.service.d/10-kubeadm.conf

WORKDIR /

RUN apk add xorriso

# Build .alpine into a new iso image. Output to stdout.

ENTRYPOINT [ "xorrisofs", \
  # Add Joliet attributes for Microsoft systems
  "-joliet", \
  # Enable Rock Ridge and set to read-only for everybody
  "-rational-rock", \
  "alpine" ]