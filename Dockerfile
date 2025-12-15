# -----------------------
# Ubuntu 24.04 VLSI Toolbox (Multi-Arch: x86_64 & ARM64)
# -----------------------

FROM ubuntu:24.04

# Expose the target architecture (amd64, arm64)
ARG TARGETARCH

LABEL org.opencontainers.image.title="vlsi-toolbox"
LABEL org.opencontainers.image.description="Ubuntu-based VLSI/EDA toolbox (x86/ARM) for use with Distrobox"

# -----------------------
# Environment Configuration
# -----------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64"
ENV PATH="/usr/local/bin:$PATH"

# -----------------------
# Base development tools
# -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        sudo \
        g++ \
        gcc \
        make \
        cmake \
        ninja-build \
        git \
        wget \
        curl \
        tar \
        unzip \
        pkg-config \
        perl \
        python3 \
        python3-pip \
        python3-dev \
        python3-venv \
        nodejs \
        npm \
        libboost-all-dev \
        libreadline-dev \
        libffi-dev \
        zlib1g-dev \
        tcl \
        tcl-dev \
        tk \
        tk-dev \
        ruby \
        ruby-dev \
        libgit2-dev \
        autoconf \
        automake \
        libtool \
        bison \
        flex \
        libfl-dev \
        gperf \
        ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------
# Core VLSI / EDA tools from Ubuntu repos
# -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        yosys \
        yosys-dev \
        iverilog \
        verilator \
        gtkterm \
        urjtag \
        magic \
        ngspice \
        ghdl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------
# Haskell tooling
# -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ghc \
        haskell-stack \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------
# Python-based tools
# -----------------------
RUN pip3 install --no-cache-dir \
        apio \
        yowasp-yosys \
        yowasp-nextpnr-ice40

# -----------------------
# Bender (ETH Zurich dependency manager)
# -----------------------
WORKDIR /tmp
RUN curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init | sh \
    && install -m 0755 bender /usr/local/bin/bender \
    && rm bender

# # -----------------------
# # Build HiGHS Solver from source
# # (Missing in Ubuntu 24.04 repos, required for OpenROAD)
# # -----------------------
# RUN git clone https://github.com/ERGO-Code/HiGHS.git /opt/HiGHS \
#     && cd /opt/HiGHS \
#     && mkdir build \
#     && cd build \
#     && cmake .. \
#         -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         -DFAST_BUILD=ON \
#     && make -j$(nproc) \
#     && make install \
#     && ldconfig \
#     && rm -rf /opt/HiGHS

# # -----------------------
# # Build CUDD from source
# # (Required for OpenROAD/OpenSTA)
# # -----------------------
# RUN git clone https://github.com/The-OpenROAD-Project/cudd.git /opt/cudd \
#     && cd /opt/cudd \
#     && autoreconf -fiv \
#     && ./configure \
#         --enable-shared \
#         --enable-obj \
#         --enable-dddmp \
#     && make -j$(nproc) \
#     && make install \
#     && ldconfig \
#     && rm -rf /opt/cudd

# # -----------------------
# # Build OR-Tools from source
# # -----------------------
# RUN git config --global http.postBuffer 524288000 \
#     && git config --global http.version HTTP/1.1 \
#     && git clone https://github.com/google/or-tools.git /opt/or-tools \
#     && cd /opt/or-tools \
#     && git checkout tags/v9.11 -b build-v9.11 \
#     && mkdir -p build \
#     && cd build \
#     && cmake .. \
#         -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_CXX_STANDARD=20 \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         -DBUILD_DEPS=ON \
#     && make -j$(nproc) \
#     && make install \
#     && ldconfig \
#     && rm -rf /opt/or-tools

# # -----------------------
# # Build Spdlog
# # -----------------------
# RUN git clone https://github.com/gabime/spdlog.git /opt/spdlog \
#     && cd /opt/spdlog \
#     && git checkout v1.14.1 \
#     && mkdir build \
#     && cd build \
#     && cmake .. \
#         -DCMAKE_BUILD_TYPE=Release \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
#         -DSPDLOG_BUILD_SHARED=ON \
#         -DSPDLOG_FMT_EXTERNAL=OFF \
#     && make -j$(nproc) \
#     && make install \
#     && ldconfig \
#     && rm -rf /opt/spdlog

# -----------------------
# Build OpenROAD from source
# -----------------------
# 1. Clone
RUN git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git /opt/OpenROAD

WORKDIR /opt/OpenROAD

# 2. Use Official Dependency Installer
# This installs necessary libs (swig, eigen, lemon, etc) specifically for Ubuntu 24.04
# We use -base and -common to cover all build requirements.
RUN ./etc/DependencyInstaller.sh -base -common

# 3. Build using the official helper script
# We pass CMake flags to handle the GCC 13 strictness and disable LTO to prevent linker crashes.
# -w: Suppress warnings
# -fpermissive: Downgrade some errors to warnings (crucial for older codebases on GCC 13)
# -include cstdint: Force include missing headers
# -d: Debug mode is OFF, Release mode is ON
RUN mkdir -p build \
    && ./etc/Build.sh \
    -cmake="-DCMAKE_INSTALL_PREFIX=/usr/local \
            -DCMAKE_CXX_STANDARD=17 \
            -DABC_ENABLE_NOWERROR=ON \
            -DBUILD_SPDLOG=OFF \
            -DLINK_TIME_OPTIMIZATION=OFF \
            -DCMAKE_CXX_FLAGS='-w -fpermissive -std=c++17 -include cstdint -include limits -include cstddef -Wno-error'" \
    && cd build \
    && make install \
    && ldconfig \
    && rm -rf /opt/OpenROAD

# -----------------------
# Qt5 dependencies for KLayout
# -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        qtbase5-dev \
        qtmultimedia5-dev \
        libqt5xmlpatterns5-dev \
        libqt5svg5-dev \
        qttools5-dev \
        qttools5-dev-tools \
        libz-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# -----------------------
# Build KLayout from source
# -----------------------
RUN mkdir -p /opt/klayout \
    && cd /opt/klayout \
    && curl -L https://www.klayout.de/downloads/klayout-0.29.8.tar.gz \
        | tar xz --strip-components=1 \
    && ./build.sh -j$(nproc) \
    && ln -sf /opt/klayout/bin/klayout /usr/local/bin/klayout

# -----------------------
# Final cleanup
# -----------------------
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# -----------------------
# Default shell
# -----------------------
CMD ["/bin/bash"]