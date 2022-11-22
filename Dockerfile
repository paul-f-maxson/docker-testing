# syntax=docker/dockerfile:1.4
ARG ARCH_TAG=base-20221120.0.103865

FROM archlinux:${ARCH_TAG} AS base

FROM base as install-k8s

ARG SRCDIR=src
ARG CNI_PLUGINS_VERSION=1.1.1
ARG CRICTL_VERSION=1.25.0
ARG KUBEADM_VERSION=1.25.3
ARG KUBELET_SERVICE_VERSION=0.4.0
ARG K8S_ARCH=amd64
ARG CNI_DEST=/opt/cni/bin
ARG K8S_DEST=/usr/local/bin

# INSTALL K8S ON THE IMAGE
# based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2

WORKDIR /arch

# Install CNI plugins (required for most pod network):

ADD https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${K8S_ARCH}-v${CNI_PLUGINS_VERSION}.tgz /tmp/cni.tgz

RUN tar --extract --gzip --file=/tmp/cni.tgz --directory=.${CNI_DEST}


# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))

ADD https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${K8S_ARCH}.tar.gz /tmp/crictl.tgz

RUN tar --extract --gzip --file=/tmp/crictl.tgz --directory=${K8S_DEST}


# Install kubeadm, kubelet and kubectl

ADD https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubeadm ./kubeadm

ADD https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubelet ./kubelet

RUN chmod +x kubeadm && chmod +x kubelet


# Add a kubelet systemd service

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${K8S_DEST}:g" > ./etc/systemd/system/kubelet.service

RUN mkdir -p ./etc/systemd/system/kubelet.service.d

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${K8S_DEST}:g" > ./etc/systemd/system/kubelet.service.d/10-kubeadm.conf

WORKDIR /

FROM base as build-iso

RUN pacman -Syu --assume-yes archiso

ENTRYPOINT [ "archiso"]