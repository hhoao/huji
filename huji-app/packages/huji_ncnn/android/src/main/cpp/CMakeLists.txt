cmake_minimum_required(VERSION 3.18)

project(huji_ncnn LANGUAGES CXX)

# === ncnn prebuilt (Vulkan, static) ===
# Downloads the official ncnn android-vulkan release once per build dir.
# Override by pre-extracting into ${NCNN_ROOT_DIR} for offline CI.
set(NCNN_VERSION "20260526" CACHE STRING "ncnn release tag")

if(NOT DEFINED NCNN_ROOT_DIR OR NOT EXISTS "${NCNN_ROOT_DIR}/${ANDROID_ABI}/lib/libncnn.a")
  set(NCNN_ROOT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn" CACHE PATH "ncnn root (<abi>/include,<abi>/lib)" FORCE)
endif()

if(NOT EXISTS "${NCNN_ROOT_DIR}/${ANDROID_ABI}/lib/libncnn.a")
  set(NCNN_ZIP_URL
      "https://github.com/Tencent/ncnn/releases/download/${NCNN_VERSION}/ncnn-${NCNN_VERSION}-android-vulkan.zip")
  set(NCNN_ZIP "${CMAKE_CURRENT_BINARY_DIR}/ncnn.zip")
  message(STATUS "Downloading ncnn: ${NCNN_ZIP_URL}")
  file(DOWNLOAD ${NCNN_ZIP_URL} ${NCNN_ZIP} SHOW_PROGRESS)
  file(ARCHIVE_EXTRACT INPUT ${NCNN_ZIP} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
  # Archive layout: ncnn-<ver>-android-vulkan/<abi>/{include,lib}
  file(GLOB NCNN_EXTRACTED_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract/ncnn-*")
  list(GET NCNN_EXTRACTED_DIR 0 NCNN_SRC_DIR)
  file(COPY "${NCNN_SRC_DIR}/" DESTINATION "${NCNN_ROOT_DIR}")
  file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
  file(REMOVE ${NCNN_ZIP})
endif()

set(NCNN_LIB_DIR "${NCNN_ROOT_DIR}/${ANDROID_ABI}/lib")
set(NCNN_INC_DIR "${NCNN_ROOT_DIR}/${ANDROID_ABI}/include")

add_library(huji_ncnn_plugin SHARED
  ../../../../src/huji_ncnn_api.cpp)

target_compile_features(huji_ncnn_plugin PRIVATE cxx_std_17)
target_include_directories(huji_ncnn_plugin PRIVATE
  ../../../../src
  ${NCNN_INC_DIR})

# ncnn static core + its static deps (glslang stack) + OpenMP.
target_link_libraries(huji_ncnn_plugin PRIVATE
  ${NCNN_LIB_DIR}/libncnn.a
  ${NCNN_LIB_DIR}/libglslang.a
  ${NCNN_LIB_DIR}/libglslang-default-resource-limits.a
  ${NCNN_LIB_DIR}/libMachineIndependent.a
  ${NCNN_LIB_DIR}/libGenericCodeGen.a
  ${NCNN_LIB_DIR}/libOSDependent.a
  ${NCNN_LIB_DIR}/libSPIRV.a
  -fopenmp
  android
  jnigraphics
  log)

find_library(log-lib log)
target_link_libraries(huji_ncnn_plugin PRIVATE ${log-lib})
