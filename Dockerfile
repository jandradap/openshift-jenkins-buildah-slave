# A Dockerfile to build an OpenShift Jenkins Slave Agent.
# It's based on the OpenShift Maven image,
# which includes OpenJDK 1.8 and Maven 3.x.

# The v3.9 digest...
FROM openshift/jenkins-slave-maven-centos7:v3.9@sha256:4d0b0a6cf06eb78d36b651fd3f41e37fab09af3f0dc36553b72886db0929100d
MAINTAINER Alan Christie (alanbchristie)

ENV INSTALL_PATH /project-atomic
ENV OC_TOOL_PATH /oc-tool

ENV GOPATH ${INSTALL_PATH}

USER root

# Install gcc (required to build buildah)
RUN yum -y group install "Development Tools"

# Install packages required by buildah, podman and skopeo
RUN yum -y install \
    atomic-registries \
    bats \
    btrfs-progs-devel \
    bzip2 \
    conmon \
    containernetworking-cni \
    device-mapper-devel \
    git \
    glibc-devel \
    glibc-static \
    glib2-devel \
    go \
    go-md2man \
    golang \
    golang-github-cpuguy83-go-md2man \
    gpgme-devel \
    iptables \
    libassuan-devel \
    libgpg-error-devel \
    libseccomp-devel \
    libselinux-devel \
    make \
    ostree-devel \
    pkgconfig \
    runc \
    skopeo-containers

# Get the OpenShift Origin OC CLI tools ---------------------------------------

ENV OC_VERSION 3.9.0
ENV OC_SRC openshift-origin-client-tools-v${OC_VERSION}-191fece-linux-64bit

WORKDIR ${OC_TOOL_PATH}
RUN wget https://github.com/openshift/origin/releases/download/v${OC_VERSION}/${OC_SRC}.tar.gz && \
    tar -xvzf ${OC_SRC}.tar.gz && \
    mv ${OC_SRC}/* . && \
    rm ${OC_SRC}.tar.gz && \
    rmdir ${OC_SRC}
ENV PATH = ${PATH}:${OC_TOOL_PATH}

# Get, make and install podman ------------------------------------------------

ENV PODMAN_VERSION 0.6.5
ENV PODMAN_SUB_PATH src/github.com/projectatomic/libpod

WORKDIR ${INSTALL_PATH}
RUN git clone https://github.com/projectatomic/libpod ./${PODMAN_SUB_PATH}
WORKDIR ${PODMAN_SUB_PATH}
RUN git checkout tags/v${PODMAN_VERSION} 2> /dev/null
RUN make install.tools; make BUILDTAGS='seccomp selinux apparmor'; make install

# Get, make and install skopeo ------------------------------------------------

ENV SKOPEO_VERSION 0.1.31
ENV SKOPEO_SUB_PATH src/github.com/projectatomic/skopeo

WORKDIR ${INSTALL_PATH}
RUN git clone https://github.com/projectatomic/skopeo ./${SKOPEO_SUB_PATH}
WORKDIR ${SKOPEO_SUB_PATH}
RUN git checkout tags/v${SKOPEO_VERSION} 2> /dev/null
RUN make binary-local; make install

# Get, make and install buildah -----------------------------------------------

ENV BUILDAH_VERSION 1.3
ENV BUILDAH_SUB_PATH src/github.com/projectatomic/buildah

WORKDIR ${INSTALL_PATH}
RUN git clone https://github.com/projectatomic/buildah ./${BUILDAH_SUB_PATH}
WORKDIR ${BUILDAH_SUB_PATH}
RUN git checkout tags/v${BUILDAH_VERSION}
RUN make; make install

# Wrap-up ---------------------------------------------------------------------

# Some handy labels...
LABEL buildah.version=${BUILDAH_VERSION}
LABEL podman.version=${PODMAN_VERSION}
LABEL scopeo.version=${SKOPEO_VERSION}
LABEL oc.version=${OC_VERSION}
LABEL name="Jenkins Buildah Slave Agent"
LABEL author="Alan Christie (alanbchristie)"

# Buildah needs to run as root.
# We're root at this stage of the script, so leave the USER alone.
# Do not return to the underlying user id (1001).
WORKDIR ${HOME}
