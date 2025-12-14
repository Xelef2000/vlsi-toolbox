# -----------------------
# Fedora 43 VLSI Toolbox
# -----------------------

FROM fedora:43

LABEL org.opencontainers.image.title="vlsi-toolbox"
LABEL org.opencontainers.image.description="Fedora-based VLSI/EDA toolbox for use with Distrobox"
LABEL org.opencontainers.image.source="https://github.com/YOURUSER/vlsi-toolbox"
LABEL org.opencontainers.image.licenses="MIT"

# -----------------------
# Enable RPM Fusion
# -----------------------
RUN dnf -y install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# -----------------------
# Base development tools
# -----------------------
RUN dnf -y install \
        gcc \
        gcc-c++ \
        make \
        cmake \
        ninja-build \
        git \
        wget \
        curl \
        tar \
        unzip \
        pkgconf \
        which \
        perl \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-devel \
        nodejs \
        npm \
        # java-17-openjdk-devel \
        boost-devel \
        readline-devel \
        libffi-devel \
        zlib-devel \
        yosys \
        yosys-devel \
        tcl \
        tcl-devel \
        ruby \
        ruby-devel \
        libgit2-devel \
        autoconf \
        automake \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

# -----------------------
# Core VLSI / EDA tools
# -----------------------
RUN dnf -y install \
        iverilog \
        verilator \
        gtkterm \
        urjtag \
        magic \
        ngspice \
        ghdl \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf


# -----------------------
# Haskell tooling
# -----------------------
RUN dnf -y install ghc stack \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

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
# Dependencies for OpenROAD and OR-Tools
# (Removed 'protobuf-devel' as it conflicts with OR-Tools' internal build)
# -----------------------
RUN dnf -y install \
        clang \
        clang-devel \
        llvm \
        llvm-devel \
        gcc-c++ \
        cmake \
        make \
        swig \
        boost-devel \
        eigen3-devel \
        tcl \
        tcl-devel \
        tk \
        tk-devel \
        zlib-devel \
        readline-devel \
        libffi-devel \
        python3 \
        python3-devel \
        git \
        gtest-devel \
        spdlog-devel \
        bison \
        flex \
        yaml-cpp-devel \
        coin-or-lemon-devel \
        abseil-cpp-devel \
        scip \
        libscip-devel \
        libscip \
        coin-or-CoinUtils-devel \
        coin-or-Osi-devel \
        coin-or-Clp-devel \
        coin-or-Cgl-devel \
        coin-or-Cbc-devel \
        zlib-static \
        coin-or-HiGHS-devel \
        google-benchmark-devel \
        libtool \
        re2-devel \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

# -----------------------
# Build and Install CUDD from source (Required for OpenROAD/OpenSTA)
# RE-RUNNING to ensure a clean install
# -----------------------
RUN rm -rf /opt/cudd /usr/local/lib/libcudd.* /usr/local/include/cudd.h \
    && git clone https://github.com/The-OpenROAD-Project/cudd.git /opt/cudd \
    && cd /opt/cudd \
    && autoreconf -fiv \ 
    && ./configure \
        --enable-shared \
        --enable-obj \
        --enable-dddmp \
    && make -j$(nproc) \
    && make install \
    && rm -rf /opt/cudd

# -----------------------
# Build OR-Tools from source
# (Added -DBUILD_DEPS=ON to use internal, compatible dependencies)
# -----------------------
RUN git config --global http.postBuffer 524288000 \ 
    && git config --global http.version HTTP/1.1 \
    && git clone https://github.com/google/or-tools.git /opt/or-tools \
    && cd /opt/or-tools \
    && git checkout tags/v9.11 -b build-v9.11 \
    && mkdir -p build \
    && cd build \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=20 \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_DEPS=ON \
    && make -j$(nproc) \
    && make install \
    && rm -rf /opt/or-tools


RUN git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git /opt/OpenROAD \
    && cd /opt/OpenROAD \
    && mkdir -p build \
    && cd build \
    && cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_CXX_STANDARD=17 \
        -DABC_ENABLE_NOWERROR=ON \
        -DCMAKE_CXX_FLAGS="-Wno-error=maybe-uninitialized -Wno-error=uninitialized" \
        -DCMAKE_C_FLAGS="-Wno-error=maybe-uninitialized -Wno-error=uninitialized" \
        -DPYTHON_EXECUTABLE=$(which python3) \
    && make -j$(nproc) 2>&1 | tee build.log \
    && make install \
    && rm -rf /opt/OpenROAD/build/CMakeFiles \
    && rm -rf /opt/OpenROAD/build/third-party
    
ENV PATH="/usr/local/bin:$PATH"

# -----------------------
# Cleanup remaining steps (Optional, but good practice)
# -----------------------
# Adjust the PATH to reflect the new install prefix.
# The original ENV PATH="/opt/OpenROAD/build/bin:$PATH" is no longer needed 
# if we use 'make install' which defaults to /usr/local/bin
# (I've updated the ENV PATH below)
ENV PATH="/opt/OpenROAD/build/bin:$PATH"


# -----------------------
# Build KLayout from source
# -----------------------

# Qt5 dependencies (Fedora naming)
RUN dnf -y install \
        qt5-qtbase \
        qt5-qtbase-devel \
        qt5-qtmultimedia \
        qt5-qtmultimedia-devel \
        qt5-qtxmlpatterns \
        qt5-qtxmlpatterns-devel \
        qt5-qtsvg \
        qt5-qtsvg-devel \
        qt5-qttools \
        qt5-qttools-devel \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

# Build KLayout
RUN mkdir -p /opt/klayout \
    && cd /opt/klayout \
    && curl -L https://www.klayout.de/building/klayout-latest.tar.gz \
        | tar xz --strip-components=1 \
    && ./build.sh

ENV PATH="/opt/klayout/bin:$PATH"

# -----------------------
# Default shell
# -----------------------
CMD ["/bin/bash"]