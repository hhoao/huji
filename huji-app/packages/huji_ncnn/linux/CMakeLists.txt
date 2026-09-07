# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "huji_ncnn")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "huji_ncnn_plugin")

# === ncnn prebuilt (Vulkan) ===
# Downloads the official ncnn ubuntu release once per build dir and links
# its shared lib. Override the location by pre-extracting a package into
# ${NCNN_ROOT_DIR} (e.g. for offline CI).
set(NCNN_VERSION "20260526" CACHE STRING "ncnn release tag")
set(NCNN_UBUNTU_VARIANT "ubuntu-2404" CACHE STRING "ncnn ubuntu variant")

if(NOT DEFINED NCNN_ROOT_DIR OR NOT EXISTS "${NCNN_ROOT_DIR}/lib/libncnn.so")
  set(NCNN_ROOT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn" CACHE PATH "ncnn root (lib/ include/)" FORCE)
endif()

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

set(NCNN_LIB "${NCNN_ROOT_DIR}/lib/libncnn.so")

list(APPEND PLUGIN_SOURCES "../src/huji_ncnn_api.cpp")

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

apply_standard_settings(${PLUGIN_NAME})

target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_17)
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${NCNN_ROOT_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE "${NCNN_LIB}")

# Bundle libncnn.so next to the plugin so the app ships it; the Vulkan
# loader itself stays a host system library.
set(huji_ncnn_bundled_libraries
  "${NCNN_LIB}"
  PARENT_SCOPE)
