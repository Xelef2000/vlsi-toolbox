FROM fedora:latest

LABEL org.opencontainers.image.title="vlsi-toolbox"
LABEL org.opencontainers.image.description="Fedora-based VLSI/EDA toolbox for use with Distrobox"
LABEL org.opencontainers.image.source="https://github.com/YOURUSER/vlsi-toolbox"
LABEL org.opencontainers.image.licenses="MIT"

# Enable RPM Fusion for extra tools
RUN dnf -y install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    && dnf -y install \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Base development tools
RUN dnf -y groupinstall "Development Tools" \
    && dnf -y install \
        gcc \
        gcc-c++ \
        make \
        cmake \
        ninja \
        git \
        wget \
        curl \
        tar \
        unzip \
        pkgconf \
        which \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        nodejs \
        npm \
        java-17-openjdk \
        boost-devel \
        readline-devel \
        libffi-devel \
        yosys-devel

# -----------------------
# Core VLSI / EDA tools
# -----------------------
RUN dnf -y install \
        yosys \
        openroad \
        nextpnr \
        gtkwave \
        iverilog \
        verilator \
        openocd \
        gtkterm \
        urjtag

# -----------------------
# FPGA / netlist tools
# -----------------------
RUN dnf -y install \
        prjtrellis \
        netlistsvg

# -----------------------
# Haskell tooling (for Clash / Bender ecosystem)
# -----------------------
RUN dnf -y install \
        ghc \
        stack

# -----------------------
# Python-based tools
# -----------------------
RUN pip3 install --no-cache-dir \
        apio \
        yowasp-yosys \
        yowasp-nextpnr-ice40

# -----------------------
# Bender (ETH Zurich)
# -----------------------
RUN curl -L https://github.com/pulp-platform/bender/releases/latest/download/bender-linux-amd64 \
        -o /usr/local/bin/bender || true \
    && curl -L https://github.com/pulp-platform/bender/releases/latest/download/bender-linux-arm64 \
        -o /usr/local/bin/bender || true \
    && chmod +x /usr/local/bin/bender || true

# -----------------------
# Nice-to-have VLSI tools
# -----------------------
RUN dnf -y install \
        klayout \
        magic \
        ngspice \
        qflow \
        ghdl

# Cleanup
RUN dnf -y clean all \
    && rm -rf /var/cache/dnf

# Default shell
CMD ["/bin/bash"]
