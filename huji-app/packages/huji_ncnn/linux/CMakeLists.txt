# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "huji_ncnn")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "huji_ncnn_plugin")

# === ncnn (Vulkan) ===
# x86_64: downloads the official ncnn ubuntu release once per build dir and
# links its shared lib. The 2204 variant is the default — it needs only
# glibc 2.35 so the binary also runs on older user distros (AppImage).
# aarch64: no official prebuilt exists — build ncnn from source instead
# (requires a C++ toolchain, ~15 min; CI runners provide it).
# Override by pre-extracting a package into ${NCNN_ROOT_DIR} for offline CI.
set(NCNN_VERSION "20260526" CACHE STRING "ncnn release tag")
set(NCNN_UBUNTU_VARIANT "ubuntu-2204" CACHE STRING "ncnn ubuntu variant (x86_64)")

if(NOT DEFINED NCNN_ROOT_DIR OR NOT EXISTS "${NCNN_ROOT_DIR}/lib/libncnn.so")
  set(NCNN_ROOT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn" CACHE PATH "ncnn root (lib/ include/)" FORCE)
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
  if(NOT EXISTS "${NCNN_ROOT_DIR}/lib/libncnn.so")
    # Build ncnn from source (official release tag) with Vulkan enabled.
    # Uses a git checkout so the glslang submodule is present (the release
    # tarball lacks it). Requires libvulkan-dev.
    include(ExternalProject)
    set(NCNN_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn-src")
    set(NCNN_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn-install")
    set(NCNN_CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${NCNN_INSTALL_DIR}
        -DNCNN_VULKAN=ON
        -DNCNN_BUILD_TOOLS=OFF
        -DNCNN_BUILD_EXAMPLES=OFF
        -DNCNN_BUILD_BENCHMARK=OFF
        -DNCNN_PYTHON=OFF
        -DNCNN_SHARED_LIB=ON
        -DCMAKE_C_FLAGS=-O2
        -DCMAKE_CXX_FLAGS=-O2)
    ExternalProject_Add(ncnn_ext
        GIT_REPOSITORY "https://github.com/Tencent/ncnn.git"
        GIT_TAG "${NCNN_VERSION}"
        GIT_SUBMODULES "glslang"
        GIT_SHALLOW TRUE
        SOURCE_DIR ${NCNN_SOURCE_DIR}
        CMAKE_ARGS ${NCNN_CMAKE_ARGS}
        INSTALL_DIR ${NCNN_INSTALL_DIR}
        BUILD_BYPRODUCTS ${NCNN_INSTALL_DIR}/lib/libncnn.so)
    # Promote the built tree to NCNN_ROOT_DIR layout via a post-build copy.
    add_custom_command(TARGET ncnn_ext POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${NCNN_INSTALL_DIR}/include" "${NCNN_ROOT_DIR}/include"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${NCNN_INSTALL_DIR}/lib" "${NCNN_ROOT_DIR}/lib")
  endif()
else()
  if(NOT EXISTS "${NCNN_ROOT_DIR}/lib/libncnn.so")
    set(NCNN_ZIP_URL
        "https://github.com/Tencent/ncnn/releases/download/${NCNN_VERSION}/ncnn-${NCNN_VERSION}-${NCNN_UBUNTU_VARIANT}-shared.zip")
    set(NCNN_ZIP "${CMAKE_CURRENT_BINARY_DIR}/ncnn.zip")
    message(STATUS "Downloading ncnn: ${NCNN_ZIP_URL}")
    file(DOWNLOAD ${NCNN_ZIP_URL} ${NCNN_ZIP} SHOW_PROGRESS)
    file(ARCHIVE_EXTRACT INPUT ${NCNN_ZIP} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
    # Archive layout: ncnn-<ver>-<variant>-shared/{include,lib}
    file(GLOB NCNN_EXTRACTED_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract/ncnn-*")
    list(GET NCNN_EXTRACTED_DIR 0 NCNN_SRC_DIR)
    file(COPY "${NCNN_SRC_DIR}/include" DESTINATION "${NCNN_ROOT_DIR}")
    file(COPY "${NCNN_SRC_DIR}/lib" DESTINATION "${NCNN_ROOT_DIR}")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
    file(REMOVE ${NCNN_ZIP})
  endif()
endif()

set(NCNN_LIB "${NCNN_ROOT_DIR}/lib/libncnn.so")

list(APPEND PLUGIN_SOURCES "../src/huji_ncnn_api.cpp")

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

apply_standard_settings(${PLUGIN_NAME})

target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_17)
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${NCNN_ROOT_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE "${NCNN_LIB}")

# On aarch64 the lib is produced by the ExternalProject — order the link
# after it exists (copy runs at ncnn_ext build time).
if(TARGET ncnn_ext)
  add_dependencies(${PLUGIN_NAME} ncnn_ext)
endif()

# Bundle the plugin and libncnn.so.1 (the real file, not the dev-time
# libncnn.so symlink — install(FILES) follows the symlink and then the
# link "libncnn.so -> libncnn.so.1" lands dangling in the bundle) so the
# app ships both; the Vulkan loader itself stays a host system library.
# Exactly ONE PARENT_SCOPE set — a second set() would clobber this value
# (PARENT_SCOPE writes never accumulate) and silently drop libs from the
# bundle (see the Windows variant's note for the same bug).
# Resolve the real file behind the libncnn.so -> libncnn.so.1 ->
# libncnn.so.1.0.<ver> symlink chain — install(FILES) on a symlink copies
# the LINK, leaving a dangling bundle entry (libncnn.so.1 in bundle/lib
# pointed at a name that was never installed; the plugin's RUNPATH masked
# it by loading from the build dir instead).
file(REAL_PATH "${NCNN_ROOT_DIR}/lib/libncnn.so.1" NCNN_REAL_LIB)
set(huji_ncnn_bundled_libraries
  $<TARGET_FILE:${PLUGIN_NAME}>
  "${NCNN_REAL_LIB}"
  PARENT_SCOPE)
