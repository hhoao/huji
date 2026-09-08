# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "huji_ncnn")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "huji_ncnn_plugin")

# === ncnn prebuilt (Vulkan) ===
# Downloads the official ncnn Windows vs2022 release once per build dir.
# Override by pre-extracting into ${NCNN_ROOT_DIR} for offline CI.
# Archive layout: ncnn-<ver>-windows-<vs>-shared/<arch>/{bin,include,lib}
# (include lives INSIDE each arch dir — there is no top-level include/).
# Resulting layout: ${NCNN_ROOT_DIR}/{include,bin,lib}.
set(NCNN_VERSION "20260526" CACHE STRING "ncnn release tag")
set(NCNN_VS_VARIANT "vs2022" CACHE STRING "ncnn Visual Studio variant")

if(NOT DEFINED NCNN_ROOT_DIR OR NOT EXISTS "${NCNN_ROOT_DIR}/lib/ncnn.lib")
  set(NCNN_ROOT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn" CACHE PATH "ncnn root (include/ bin/ lib/)" FORCE)
endif()

if(NOT EXISTS "${NCNN_ROOT_DIR}/lib/ncnn.lib")
  set(NCNN_ZIP_URL
      "https://github.com/Tencent/ncnn/releases/download/${NCNN_VERSION}/ncnn-${NCNN_VERSION}-windows-${NCNN_VS_VARIANT}-shared.zip")
  set(NCNN_ZIP "${CMAKE_CURRENT_BINARY_DIR}/ncnn.zip")
  message(STATUS "Downloading ncnn: ${NCNN_ZIP_URL}")
  file(DOWNLOAD ${NCNN_ZIP_URL} ${NCNN_ZIP} SHOW_PROGRESS)
  file(ARCHIVE_EXTRACT INPUT ${NCNN_ZIP} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
  file(GLOB NCNN_EXTRACTED_DIR "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract/ncnn-*")
  list(GET NCNN_EXTRACTED_DIR 0 NCNN_SRC_DIR)
  file(COPY "${NCNN_SRC_DIR}/x64/include" DESTINATION "${NCNN_ROOT_DIR}")
  file(COPY "${NCNN_SRC_DIR}/x64/bin/ncnn.dll" DESTINATION "${NCNN_ROOT_DIR}/bin")
  file(COPY "${NCNN_SRC_DIR}/x64/lib/ncnn.lib" DESTINATION "${NCNN_ROOT_DIR}/lib")
  file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/ncnn-extract")
  file(REMOVE ${NCNN_ZIP})
endif()

set(NCNN_IMPLIB "${NCNN_ROOT_DIR}/lib/ncnn.lib")
set(NCNN_DLL "${NCNN_ROOT_DIR}/bin/ncnn.dll")

list(APPEND PLUGIN_SOURCES "../src/huji_ncnn_api.cpp")

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

# NOTE: no apply_standard_settings() — Flutter's /W4 /WX cannot survive
# ncnn's public headers (C4251 dll-interface noise). Plain /W3, no WX.
if(MSVC)
  target_compile_options(${PLUGIN_NAME} PRIVATE /W3 /wd4251 /wd4275 /wd4996 /utf-8 /EHsc)
else()
  target_compile_options(${PLUGIN_NAME} PRIVATE -fexceptions -frtti)
endif()

target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_17)
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${NCNN_ROOT_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE "${NCNN_IMPLIB}")

# Copy ncnn.dll next to the plugin dll at build time so the app bundle
# picks it up via the standard Flutter bundle copy.
add_custom_command(
  TARGET ${PLUGIN_NAME}
  POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${NCNN_DLL}" $<TARGET_FILE_DIR:${PLUGIN_NAME}>
  COMMENT "Copying ncnn.dll")

set(huji_ncnn_bundled_libraries
  $<TARGET_FILE:${PLUGIN_NAME}>
  "${NCNN_DLL}"
  PARENT_SCOPE)

# === Standalone inference helper (huji_ncnn_helper.exe) ===
# Windows: ncnn Vulkan init crashes inside Flutter engine processes, so GPU
# inference runs in this child process instead (see huji_ncnn_helper_main.cpp).
add_executable(huji_ncnn_helper
  ../src/huji_ncnn_helper_main.cpp
  ../src/huji_ncnn_api.cpp)

if(MSVC)
  target_compile_options(huji_ncnn_helper PRIVATE /W3 /wd4251 /wd4275 /wd4996 /utf-8 /EHsc)
else()
  target_compile_options(huji_ncnn_helper PRIVATE -fexceptions -frtti)
endif()

target_compile_features(huji_ncnn_helper PRIVATE cxx_std_17)
target_include_directories(huji_ncnn_helper PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${NCNN_ROOT_DIR}/include")
target_link_libraries(huji_ncnn_helper PRIVATE "${NCNN_IMPLIB}")

set(huji_ncnn_bundled_libraries
  ${huji_ncnn_bundled_libraries}
  $<TARGET_FILE:huji_ncnn_helper>
  PARENT_SCOPE)
