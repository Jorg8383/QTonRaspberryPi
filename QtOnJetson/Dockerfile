# ===============================
# Host image (x86_64)
# ===============================
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# -------------------------------
# Build arguments
# -------------------------------
ARG UBUNTU_VERSION
ARG GCC_VERSION

ENV UBUNTU_VERSION=${UBUNTU_VERSION}
ENV GCC_VERSION=${GCC_VERSION}

# -------------------------------
# Ubuntu repositories
# -------------------------------
RUN if [ "${UBUNTU_VERSION}" = "20.04" ]; then \
        CODENAME=focal; \
    elif [ "${UBUNTU_VERSION}" = "22.04" ]; then \
        CODENAME=jammy; \
    else \
        echo "Unsupported Ubuntu version"; exit 1; \
    fi && \
    echo "deb http://archive.ubuntu.com/ubuntu ${CODENAME} main universe multiverse restricted" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu ${CODENAME}-updates main universe multiverse restricted" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu ${CODENAME}-security main universe multiverse restricted" >> /etc/apt/sources.list

# -------------------------------
# Base tools + cross toolchain
# -------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg software-properties-common \
    build-essential ninja-build \
    gcc-${GCC_VERSION} g++-${GCC_VERSION} \
    gcc-${GCC_VERSION}-aarch64-linux-gnu \
    g++-${GCC_VERSION}-aarch64-linux-gnu \
    cmake pkg-config rsync git \
    python3 bison gperf flex \
    libegl1-mesa-dev \
    libgbm-dev \
    libgl1-mesa-dev \
    libx11-xcb-dev \
    libxrender-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libfontconfig1-dev \
    libudev-dev \
    libssl-dev \
    libpq-dev \
    zlib1g-dev \
    libclang-dev \
    gettext \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------
# Toolchain env
# -------------------------------
ENV CC=aarch64-linux-gnu-gcc-${GCC_VERSION}
ENV CXX=aarch64-linux-gnu-g++-${GCC_VERSION}
ENV SYSROOT=/opt/sysroot

# -------------------------------
# Sysroot from Jetson image
# -------------------------------
COPY jetsonSysroot.tar.gz /tmp/jetsonSysroot.tar.gz

RUN mkdir -p ${SYSROOT} && \
    tar -xzf /tmp/jetsonSysroot.tar.gz -C ${SYSROOT}

# Fix absolute symlinks
RUN wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py \
    -O /usr/local/bin/sysroot-relativelinks.py && \
    chmod +x /usr/local/bin/sysroot-relativelinks.py && \
    python3 /usr/local/bin/sysroot-relativelinks.py ${SYSROOT}

# -------------------------------
# Qt sources
# -------------------------------
ARG QT_VERSION=6.10.1

RUN mkdir -p /qt/src /qt/host /qt/target && \
    cd /qt/src && \
    wget https://download.qt.io/official_releases/qt/6.10/${QT_VERSION}/submodules/qtbase-everywhere-src-${QT_VERSION}.tar.xz && \
    wget https://download.qt.io/official_releases/qt/6.10/${QT_VERSION}/submodules/qtshadertools-everywhere-src-${QT_VERSION}.tar.xz && \
    wget https://download.qt.io/official_releases/qt/6.10/${QT_VERSION}/submodules/qtdeclarative-everywhere-src-${QT_VERSION}.tar.xz && \
    tar xf qtbase-everywhere-src-${QT_VERSION}.tar.xz -C /qt/host && \
    tar xf qtshadertools-everywhere-src-${QT_VERSION}.tar.xz -C /qt/host && \
    tar xf qtdeclarative-everywhere-src-${QT_VERSION}.tar.xz -C /qt/host

# -------------------------------
# Build Qt for host
# -------------------------------
RUN cd /qt/host/qtbase-everywhere-src-${QT_VERSION} && \
    cmake -GNinja . \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/qt/host/install \
      -DCMAKE_C_COMPILER=/usr/bin/gcc \
      -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
      -DQT_BUILD_TESTS=OFF \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_FEATURE_opengl=OFF && \
    ninja && ninja install

RUN cd /qt/host/qtshadertools-everywhere-src-${QT_VERSION} && \
    /qt/host/install/bin/qt-configure-module . && \
    cmake --build . && cmake --install .

RUN cd /qt/host/qtdeclarative-everywhere-src-${QT_VERSION} && \
    /qt/host/install/bin/qt-configure-module . && \
    cmake --build . && cmake --install .

# -------------------------------
# Extract Qt sources for target
# -------------------------------
RUN tar xf /qt/src/qtbase-everywhere-src-${QT_VERSION}.tar.xz -C /qt/target && \
    tar xf /qt/src/qtshadertools-everywhere-src-${QT_VERSION}.tar.xz -C /qt/target && \
    tar xf /qt/src/qtdeclarative-everywhere-src-${QT_VERSION}.tar.xz -C /qt/target

# -------------------------------
# Toolchain file
# -------------------------------
COPY toolchain.cmake /opt/toolchain.cmake

ARG GCC_VERSION


RUN export PKG_CONFIG_SYSROOT_DIR=/opt/sysroot && \
    export PKG_CONFIG_LIBDIR=/opt/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:/opt/sysroot/usr/share/pkgconfig && \
    unset PKG_CONFIG_PATH && \
    echo "PKG_CONFIG_SYSROOT_DIR=$PKG_CONFIG_SYSROOT_DIR" && \
    pkg-config --libs xcb && \
    pkg-config --cflags xcb && \
    pkg-config --exists xcb && echo "XCB FOUND"

# -------------------------------
# Build Qt for Jetson (target)
# -------------------------------
RUN cd /qt/target/qtbase-everywhere-src-${QT_VERSION} && \
    cmake -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=/opt/toolchain.cmake \
      -DCMAKE_SYSROOT=${SYSROOT} \
      -DCMAKE_INSTALL_PREFIX=/qt/target/install \
      -DQT_HOST_PATH=/qt/host/install \
      -DGCC_VERSION=${GCC_VERSION} \
      -DQT_BUILD_TESTS=OFF \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_FEATURE_wayland=OFF \
      -DQT_FEATURE_xcb=ON \
      -DQT_FEATURE_xcb_xlib=ON \
      -DQT_FEATURE_opengl=ON \
      -DFEATURE_xcb_xlib=ON && \
    ninja && ninja install

RUN cd /qt/target/qtshadertools-everywhere-src-${QT_VERSION} && \
    /qt/target/install/bin/qt-configure-module . && \
    cmake --build . && cmake --install .

RUN cd /qt/target/qtdeclarative-everywhere-src-${QT_VERSION} && \
    /qt/target/install/bin/qt-configure-module . && \
    cmake --build . && cmake --install .

# -------------------------------
# Package result
# -------------------------------
RUN tar -czf qt6-jetson-${QT_VERSION}.tar.gz -C /qt/target/install .

RUN mkdir /project

COPY projectQml /project

RUN cd /project && \
    /qt/target/install/bin/qt-cmake . && \
    cmake --build .
