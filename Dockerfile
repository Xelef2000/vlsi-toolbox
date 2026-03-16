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
    build-essential sudo g++ gcc make cmake ninja-build git wget curl tar unzip pkg-config meson \
    perl python3 python3-pip python3-dev python3-venv nodejs npm \
    libboost-all-dev libreadline-dev libffi-dev zlib1g-dev \
    tcl tcl-dev tk tk-dev ruby ruby-dev libgit2-dev \
    autoconf automake libtool bison flex libfl-dev gperf ca-certificates libyaml-cpp-dev \
    gawk graphviz xdot \
    # Repo VLSI Tools
    iverilog verilator gtkterm urjtag magic ngspice ghdl \
    # Haskell
    ghc haskell-stack \
    # Qt5 (for KLayout)
    qtbase5-dev qtmultimedia5-dev libqt5xmlpatterns5-dev libqt5svg5-dev qttools5-dev qttools5-dev-tools libz-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build Yosys (Targeting release v0.60)
RUN git clone https://github.com/YosysHQ/yosys.git /opt/yosys \
    && cd /opt/yosys \
    && git checkout v0.60 \
    && git submodule update --init --recursive \
    && make config-gcc \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /opt/yosys

# Install sby prerequisites
RUN pip3 install --no-cache-dir click

# Build SymbiYosys (sby)
RUN git clone https://github.com/YosysHQ/sby.git /opt/sby \
    && cd /opt/sby \
    && make install \
    && cd / \
    && rm -rf /opt/sby

# Build Boolector (recommended solver for sby)
RUN git clone https://github.com/boolector/boolector.git /opt/boolector \
    && cd /opt/boolector \
    && ./contrib/setup-btor2tools.sh \
    && ./contrib/setup-lingeling.sh \
    && ./configure.sh \
    && make -C build -j$(nproc) \
    && cp build/bin/boolector build/bin/btor* /usr/local/bin/ \
    && cp deps/btor2tools/build/bin/btorsim /usr/local/bin/ \
    && cd / \
    && rm -rf /opt/boolector

# Build Yices 2 (recommended solver for sby)
RUN git clone https://github.com/SRI-CSL/yices2.git /opt/yices2 \
    && cd /opt/yices2 \
    && autoconf \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /opt/yices2

# Install Bazelisk (manages Bazel versions, works on arm64/x86)
RUN BAZELISK_VERSION=v1.25.0 \
    && case "$(uname -m)" in \
        x86_64) BAZELISK_ARCH=amd64 ;; \
        aarch64) BAZELISK_ARCH=arm64 ;; \
        *) echo "Unsupported arch" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${BAZELISK_ARCH}" \
       -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Build Z3 (optional solver for sby)
RUN git clone https://github.com/Z3Prover/z3.git /opt/z3 \
    && cd /opt/z3 \
    && bazel build //... \
    && cp bazel-bin/z3 /usr/local/bin/ \
    && cd / \
    && rm -rf /opt/z3 /root/.cache/bazel

RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh \
        fzf \
        zoxide \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Starship via official script (non-interactive)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir /usr/local/bin

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

# Install netlistsvg
RUN npm install -g netlistsvg

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["/bin/bash"]