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
#
# libncnn.a references omp_* symbols (OpenMP runtime). Linking -fopenmp
# pulls libomp.so, which AGP does NOT package into the APK — dlopen then
# fails with `library "libomp.so" not found` (the mobile clip crash).
# The static libomp.a from the NDK's clang resource dir is bundled into
# the plugin instead; same approach as ncnn's own Android samples.
if(ANDROID_ABI STREQUAL "arm64-v8a")
  set(CLANG_ABI_DIR aarch64)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
  set(CLANG_ABI_DIR arm)
elseif(ANDROID_ABI STREQUAL "x86_64")
  set(CLANG_ABI_DIR x86_64)
elseif(ANDROID_ABI STREQUAL "x86")
  set(CLANG_ABI_DIR i386)
else()
  message(FATAL_ERROR "unsupported ANDROID_ABI for static libomp: ${ANDROID_ABI}")
endif()
file(GLOB _clang_ver_dir LIST_DIRECTORIES true
     "${ANDROID_NDK}/toolchains/llvm/prebuilt/*/lib/clang/*/lib")
set(OMP_STATIC_LIB "${_clang_ver_dir}/linux/${CLANG_ABI_DIR}/libomp.a")
if(NOT EXISTS "${OMP_STATIC_LIB}")
  message(FATAL_ERROR "static libomp not found: ${OMP_STATIC_LIB}")
endif()

target_link_libraries(huji_ncnn_plugin PRIVATE
  ${NCNN_LIB_DIR}/libncnn.a
  ${NCNN_LIB_DIR}/libglslang.a
  ${NCNN_LIB_DIR}/libglslang-default-resource-limits.a
  ${NCNN_LIB_DIR}/libMachineIndependent.a
  ${NCNN_LIB_DIR}/libGenericCodeGen.a
  ${NCNN_LIB_DIR}/libOSDependent.a
  ${NCNN_LIB_DIR}/libSPIRV.a
  ${OMP_STATIC_LIB}
  android
  jnigraphics
  log)

find_library(log-lib log)
target_link_libraries(huji_ncnn_plugin PRIVATE ${log-lib})
