FROM ubuntu:24.04

ARG TARGETARCH

LABEL org.opencontainers.image.title="vlsi-toolbox" \
      org.opencontainers.image.description="Ubuntu-based VLSI/EDA toolbox (x86/ARM) for use with Distrobox"

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64" \
    PATH="/usr/local/bin:$PATH"

# Install base dev tools, repository VLSI tools, Haskell, and Qt5 dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base Development
    build-essential sudo g++ gcc make cmake ninja-build git wget curl tar unzip pkg-config \
    perl python3 python3-pip python3-dev python3-venv nodejs npm \
    libboost-all-dev libreadline-dev libffi-dev zlib1g-dev \
    tcl tcl-dev tk tk-dev ruby ruby-dev libgit2-dev \
    autoconf automake libtool bison flex libfl-dev gperf ca-certificates libyaml-cpp-dev \
    # Repo VLSI Tools
    yosys yosys-dev iverilog verilator gtkterm urjtag magic ngspice ghdl \
    # Haskell
    ghc haskell-stack \
    # Qt5 (for KLayout)
    qtbase5-dev qtmultimedia5-dev libqt5xmlpatterns5-dev libqt5svg5-dev qttools5-dev qttools5-dev-tools libz-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python Tools
RUN pip3 install --no-cache-dir apio yowasp-yosys yowasp-nextpnr-ice40

# Bender (ETH Zurich dependency manager)
WORKDIR /tmp
RUN curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init | sh \
    && install -m 0755 bender /usr/local/bin/bender \
    && rm bender


RUN apt-get update && apt-get install -y --no-install-recommends \
    qtbase5-dev qtmultimedia5-dev libqt5xmlpatterns5-dev libqt5svg5-dev \
    qttools5-dev qttools5-dev-tools libz-dev libqt5charts5-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build OpenROAD
RUN git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git /opt/OpenROAD
WORKDIR /opt/OpenROAD
RUN ./etc/DependencyInstaller.sh -base -common

# Build with GCC 13 compatibility flags (-fpermissive, includes) and disable LTO to prevent linker crashes
RUN mkdir -p build \
    && ./etc/Build.sh \
    -cmake="-DCMAKE_INSTALL_PREFIX=/usr/local \
            -DCMAKE_CXX_STANDARD=17 \
            -DABC_ENABLE_NOWERROR=ON \
            -DBUILD_SPDLOG=OFF \
            -DBUILD_GUI=ON \
            -DLINK_TIME_OPTIMIZATION=OFF \
            -DCMAKE_CXX_FLAGS='-w -fpermissive -std=c++17 -include cstdint -include limits -include cstddef -Wno-error'" \
    && cd build && make install && ldconfig \
    && rm -rf /opt/OpenROAD

# Build KLayout
RUN mkdir -p /opt/klayout \
    && cd /opt/klayout \
    && curl -L https://www.klayout.org/downloads/source/klayout-0.30.5.tar.gz | tar xz --strip-components=1 \
    && ./build.sh -j$(nproc) \
    && ln -sf /opt/klayout/bin/klayout /usr/local/bin/klayout

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["/bin/bash"]