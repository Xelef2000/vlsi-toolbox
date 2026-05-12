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
    iverilog gtkterm urjtag magic ngspice ghdl \
    # Haskell
    ghc haskell-stack \
    # Qt5 (for KLayout)
    qtbase5-dev qtmultimedia5-dev libqt5xmlpatterns5-dev libqt5svg5-dev qttools5-dev qttools5-dev-tools libz-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build Verilator 4.228 (required for vrtlmod compatibility)
RUN git clone https://github.com/verilator/verilator.git /opt/verilator \
    && cd /opt/verilator \
    && git checkout v4.228 \
    && autoconf \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /opt/verilator

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

RUN apt-get update && apt-get install -y --no-install-recommends \
        zsh \
        fzf \
        zoxide \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Starship via official script (non-interactive)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y --bin-dir /usr/local/bin

# Python Tools
RUN pip3 install --no-cache-dir --ignore-installed apio yowasp-yosys yowasp-nextpnr-ice40 go-task-bin matplotlib cocotb pytest

# Bender (ETH Zurich dependency manager)
WORKDIR /tmp
RUN curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init | sh \
    && install -m 0755 bender /usr/local/bin/bender \
    && rm bender

RUN apt-get update && apt-get install -y --no-install-recommends \
    qtbase5-dev qtmultimedia5-dev libqt5xmlpatterns5-dev libqt5svg5-dev \
    qttools5-dev qttools5-dev-tools libz-dev libqt5charts5-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build OpenROAD 26Q2
RUN git clone --recursive --depth 1 --branch 26Q2 https://github.com/The-OpenROAD-Project/OpenROAD.git /opt/OpenROAD
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

# Install LLVM/Clang (required for vrtlmod)
RUN apt-get update && apt-get install -y --no-install-recommends \
    llvm-15-dev libclang-15-dev clang-15 libzstd-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build SystemC 2.3.3 (required for vrtlmod)
RUN git clone --depth 1 --branch 2.3.3 https://github.com/accellera-official/systemc.git /opt/systemc_src \
    && cd /opt/systemc_src \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=OFF \
       -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    && cmake --build build --parallel $(nproc) --target install \
    && cd / \
    && rm -rf /opt/systemc_src

# Build vrtlmod
ENV SYSTEMC_HOME=/usr/local \
    LLVM_DIR=/usr/lib/llvm-15/lib/cmake/llvm \
    VERILATOR_ROOT=/usr/local
RUN rm -rf /usr/local/lib/cmake/Boost* /usr/local/lib/cmake/boost* /usr/local/lib/libboost* /usr/local/include/boost \
    && git clone --recursive --depth 1 https://github.com/tum-ei-eda/vrtlmod.git /opt/vrtlmod \
    && cd /opt/vrtlmod \
    && git submodule update --init --recursive \
    && cmake -S . -B build -DLLVM_DIR=$LLVM_DIR -DVERILATOR_ROOT=$VERILATOR_ROOT -DBUILD_TESTING=OFF \
       -DCMAKE_INSTALL_PREFIX=/usr/local \
       -DBoost_INCLUDE_DIR=/usr/include -DBoost_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu \
    && cmake --build build --parallel $(nproc) \
    && cmake --build build --target install \
    && cd / \
    && rm -rf /opt/vrtlmod

# Install TMRG (Triple Modular Redundancy Generator)
RUN git clone https://gitlab.cern.ch/tmrg/tmrg.git /opt/tmrg \
    && pip3 install --no-cache-dir /opt/tmrg \
    && rm -rf /opt/tmrg

# Install netlistsvg
RUN npm install -g netlistsvg

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Build and install yosys-slang plugin
RUN git clone --recursive https://github.com/povik/yosys-slang.git /opt/yosys-slang \
    && cd /opt/yosys-slang \
    && make -j$(nproc) \
    && install -d /usr/local/share/yosys/plugins \
    && install -m 0755 build/slang.so /usr/local/share/yosys/plugins/slang.so \
    && cd / \
    && rm -rf /opt/yosys-slang

CMD ["/bin/bash"]
