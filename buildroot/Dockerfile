# SeedSigner Self-Contained Build - No Home Directory Pollution!
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install all required packages including ca-certificates for git cloning
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        python3 \
        python3-pip \
        ssh \
        make gcc \
        gcc-multilib g++-multilib \
        module-assistant expect g++ gawk \
        texinfo libssl-dev bison flex \
        fakeroot cmake unzip gperf autoconf \
        device-tree-compiler libncurses5-dev \
        pkg-config bc python-is-python3 passwd openssl \
        openssh-server openssh-client vim file cpio rsync \
        ca-certificates \
        && \
    rm -rf /var/lib/apt/lists/*

# Set working directory for self-contained builds
WORKDIR /build

# Create directories for all components
RUN mkdir -p /build/repos /build/output

# Copy build scripts and configuration files
COPY configs/ /build/configs/
COPY files/ /build/files/
COPY add_package_buildroot.sh /build/
COPY blkenvflash /build/
COPY sdk_init.sh /build/

# Make scripts executable
RUN chmod +x /build/*.sh /build/blkenvflash 2>/dev/null || true

# Set up git configuration (required for cloning repositories inside container)
RUN git config --global user.email "build@seedsigner.luckfox" && \
    git config --global user.name "SeedSigner Build"

# Create required files for SDK toolchain
RUN touch /root/.bash_profile

SHELL ["/bin/bash", "-c"]

# Copy build automation script
COPY docker-automation.sh /build/
RUN chmod +x /build/docker-automation.sh

# Set the entrypoint
ENTRYPOINT ["/build/docker-automation.sh"]
CMD ["auto"]
