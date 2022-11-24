# syntax=docker/dockerfile:1.4
ARG ARCH_TAG=base-20221120.0.103865

FROM archlinux:${ARCH_TAG} AS base

ARG PROFILEDIR

COPY --link ${PROFILEDIR} /profile

FROM base as install-k8s

ARG CNI_PLUGINS_VERSION=1.1.1
ARG CRICTL_VERSION=1.25.0
ARG KUBEADM_VERSION=1.25.3
ARG KUBELET_SERVICE_VERSION=0.4.0
ARG K8S_ARCH=amd64
ARG CNI_DEST=/opt/cni/bin
ARG K8S_DEST=/usr/local/bin

# INSTALL K8S ON THE IMAGE
# based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-2

WORKDIR /profile/airootfs

# Install CNI plugins (required for most pod network):

RUN mkdir -p .${CNI_DEST}

RUN curl -sSL https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${K8S_ARCH}-v${CNI_PLUGINS_VERSION}.tgz | tar --extract --gzip --directory=.${CNI_DEST}


# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))

RUN mkdir -p .${K8S_DEST}

RUN curl -sSL https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${K8S_ARCH}.tar.gz | tar --extract --gzip  --directory=.${K8S_DEST}


# Install kubeadm, kubelet and kubectl

RUN curl -sSL https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubeadm > ./kubeadm

RUN curl -sSL https://dl.k8s.io/release/v${KUBEADM_VERSION}/bin/linux/${K8S_ARCH}/kubelet > ./kubelet

RUN chmod +x kubeadm && chmod +x kubelet


# Add a kubelet systemd service

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${K8S_DEST}:g" > ./etc/systemd/system/kubelet.service

RUN mkdir -p ./etc/systemd/system/kubelet.service.d

RUN curl -sSL "https://raw.githubusercontent.com/kubernetes/release/v${KUBELET_SERVICE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${K8S_DEST}:g" > ./etc/systemd/system/kubelet.service.d/10-kubeadm.conf

WORKDIR /


FROM install-k8s as build-iso

RUN pacman --sync --refresh --sysupgrade --noconfirm archiso

ENTRYPOINT [ "mkarchiso", "-v", "-o", "/out", "-w", "/tmp/archiso-tmp", "/profile"]