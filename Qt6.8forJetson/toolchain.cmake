cmake_minimum_required(VERSION 3.20)
include_guard(GLOBAL)

# -------------------------------------------------
# GCC version (JP5=9, JP6=11)
# -------------------------------------------------
if(NOT DEFINED GCC_VERSION)
    if(DEFINED ENV{GCC_VERSION})
        set(GCC_VERSION $ENV{GCC_VERSION})
    else()
        message(FATAL_ERROR "GCC_VERSION not set (9 for JP5, 11 for JP6)")
    endif()
endif()

message(STATUS "Using GCC_VERSION=${GCC_VERSION}")

# -------------------------------------------------
# Target system
# -------------------------------------------------
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(TARGET_SYSROOT /opt/sysroot)
set(TARGET_TRIPLE aarch64-linux-gnu)

set(CMAKE_SYSROOT ${TARGET_SYSROOT})

# -------------------------------------------------
# Compilers
# -------------------------------------------------
set(CMAKE_C_COMPILER   /usr/bin/${TARGET_TRIPLE}-gcc-${GCC_VERSION})
set(CMAKE_CXX_COMPILER /usr/bin/${TARGET_TRIPLE}-g++-${GCC_VERSION})

# -------------------------------------------------
# pkg-config (TARGET ONLY)
# -------------------------------------------------
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${TARGET_SYSROOT})
set(ENV{PKG_CONFIG_LIBDIR}
    ${TARGET_SYSROOT}/usr/lib/${TARGET_TRIPLE}/pkgconfig:${TARGET_SYSROOT}/usr/share/pkgconfig:${TARGET_SYSROOT}/usr/lib/pkgconfig
)
unset(ENV{PKG_CONFIG_PATH})

# -------------------------------------------------
# Search paths
# -------------------------------------------------
set(CMAKE_FIND_ROOT_PATH ${TARGET_SYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# -------------------------------------------------
# Flags (Jetson-safe)
# -------------------------------------------------
set(CMAKE_C_FLAGS_INIT   "--sysroot=${TARGET_SYSROOT}")
set(CMAKE_CXX_FLAGS_INIT "--sysroot=${TARGET_SYSROOT}")

# -------------------------------------------------
# RPATH
# -------------------------------------------------
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
