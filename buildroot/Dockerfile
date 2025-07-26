# THIS MUST BE BUILD ON A X86/64 MACHINE OR WITH X86 EMULATION!
# Some APT packages are unavailable on ARM!

# Use buildx for cross-platform builds with emulation
# This allows ARM64 Macs to run x86_64 builds via emulation  
FROM --platform=linux/amd64 ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Install required packages
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
        && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

RUN touch /root/.bash_profile

COPY sdk_init.sh /etc/profile.d/
COPY add_package_buildroot.sh .

RUN chmod +x /etc/profile.d/sdk_init.sh && \
    echo 'source /etc/profile.d/sdk_init.sh' >> /etc/bash.bashrc

SHELL ["/bin/bash", "-c"]

# Copy build automation scripts
COPY build_automation.sh /app/
COPY validate_environment.sh /app/
RUN chmod +x /app/build_automation.sh /app/validate_environment.sh

# Set the entrypoint - can be overridden for interactive mode
ENTRYPOINT ["/app/build_automation.sh"]
CMD ["auto"]
