cmake_minimum_required(VERSION 3.20)

project(duckdb_graphar)
set(EXTENSION_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Extension root directory")

# =============================================
# Core Configuration
# =============================================
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(UNIX AND NOT APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libstdc++ -static-libgcc")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++ -static-libgcc")
#    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -static-libstdc++ -static-libgcc")
endif()

include(FetchContent)
include(GNUInstallDirs)
include(ExternalProject)

option(LOAD_TESTS "Build extension tests" OFF)
option(SHOW_LOG_STAGES "Display progress logs for each stage" ON)

# =============================================
# Progress Reporting Functions
# =============================================
function(log_stage MESSAGE)
    if(SHOW_LOG_STAGES)
        message(STATUS ">>> [${PROJECT_NAME}] ${MESSAGE}")
    endif()
endfunction()

function(log_done)
    if(SHOW_LOG_STAGES)
        message(STATUS ">>> [${PROJECT_NAME}] Done.")
    endif()
endfunction()

# =============================================
# Dependency Management
# =============================================
set(DEPS_INSTALL_DIR ${CMAKE_BINARY_DIR}/_deps)
set(ARROW_INSTALL_DIR ${DEPS_INSTALL_DIR}/arrow-install)
set(GRAPHAR_INSTALL_DIR ${DEPS_INSTALL_DIR}/graphar-install)

set(ARROW_PREFIX_DIR ${DEPS_INSTALL_DIR}/arrow-prefix)
set(GRAPHAR_PREFIX_DIR ${DEPS_INSTALL_DIR}/graphar-prefix)

set(ARROW_LIB_DIR ${ARROW_INSTALL_DIR}/lib)
set(GRAPHAR_LIB_DIR ${GRAPHAR_INSTALL_DIR}/lib)

# Arrow
log_stage("Configuring Apache Arrow...")

ExternalProject_Add(
  arrow
  PREFIX ${ARROW_PREFIX_DIR}
  GIT_REPOSITORY https://github.com/apache/arrow.git
  GIT_TAG apache-arrow-19.0.1
  SOURCE_SUBDIR cpp
  CMAKE_ARGS
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON

    -DARROW_BUILD_SHARED=OFF
    -DARROW_BUILD_STATIC=ON
    -DARROW_BUILD_TESTS=OFF
    -DARROW_BUILD_BENCHMARKS=OFF
    -DARROW_DEPENDENCY_USE_SHARED=OFF

    -DARROW_CSV=ON
    -DARROW_JSON=ON
    -DARROW_ORC=ON
    -DARROW_PARQUET=ON
    -DARROW_S3=ON

    -DARROW_WITH_SNAPPY=ON
    -DARROW_RPATH_ORIGIN=ON

    -DARROW_BOOST_USE_SHARED=OFF
    -DARROW_BROTLI_USE_SHARED=OFF
    -DARROW_BUILD_TESTS=OFF
    -DARROW_BZ2_USE_SHARED=OFF
    -DARROW_ENABLE_TIMING_TESTS=OFF
    -DARROW_GFLAGS_USE_SHARED=OFF
    -DARROW_GRPC_USE_SHARED=OFF
    -DARROW_JEMALLOC_USE_SHARED=OFF
    -DARROW_LLVM_USE_SHARED=OFF
    -DARROW_LZ4_USE_SHARED=OFF
    -DARROW_OPENSSL_USE_SHARED=OFF
    -DARROW_PROTOBUF_USE_SHARED=OFF
    -DARROW_SNAPPY_USE_SHARED=OFF
    -DARROW_THRIFT_USE_SHARED=OFF
    -DARROW_UTF8PROC_USE_SHARED=OFF
    -DARROW_ZSTD_USE_SHARED=OFF

    -DCMAKE_INSTALL_PREFIX=${ARROW_INSTALL_DIR}
  BUILD_ALWAYS OFF
  INSTALL_DIR ${ARROW_INSTALL_DIR}
)

add_library(arrow::arrow_static STATIC IMPORTED GLOBAL)

file(MAKE_DIRECTORY "${ARROW_INSTALL_DIR}/include")
set_target_properties(arrow::arrow_static PROPERTIES
  IMPORTED_LOCATION "${ARROW_LIB_DIR}/libarrow.a"
  INTERFACE_INCLUDE_DIRECTORIES ${ARROW_INSTALL_DIR}/include
)

add_dependencies(arrow::arrow_static arrow)

# GraphAr

log_stage("Setting up GraphAR...")

set(BUILD_SHELL OFF CACHE BOOL "")

ExternalProject_Add(
  graphar
  PREFIX ${GRAPHAR_PREFIX_DIR}
  GIT_REPOSITORY https://github.com/apache/incubator-graphar.git
  GIT_TAG 1a44bc343e0e846df129c78152f6310a1d678429
  SOURCE_SUBDIR cpp
  CMAKE_ARGS
    -DUSE_STATIC_ARROW=ON
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DCMAKE_INSTALL_PREFIX=${GRAPHAR_INSTALL_DIR}
    -DCMAKE_PREFIX_PATH=${ARROW_INSTALL_DIR}
    -DProtobuf_INCLUDE_DIR=${ARROW_PREFIX_DIR}/src/arrow-build/protobuf_ep-install/include
    -DProtobuf_LIBRARIES=${ARROW_PREFIX_DIR}/src/arrow-build/protobuf_ep-install/lib/libprotobuf.a
  INSTALL_DIR ${GRAPHAR_INSTALL_DIR}
  DEPENDS arrow
)

add_library(graphar::graphar_static STATIC IMPORTED GLOBAL)

set_target_properties(graphar::graphar_static PROPERTIES
  IMPORTED_LOCATION "${GRAPHAR_LIB_DIR}/libgraphar.a"
)

add_dependencies(graphar::graphar_static graphar arrow)

log_done()

# DuckDB
set(DUCKDB_EXTENSION_CONFIGS "${CMAKE_CURRENT_SOURCE_DIR}/config/extension_config.cmake")
set(ARROW_LIBS
    graphar::graphar_static
    arrow::arrow_static
    "${ARROW_LIB_DIR}/libarrow_acero.a"
    "${ARROW_LIB_DIR}/libarrow_bundled_dependencies.a"
    "${ARROW_LIB_DIR}/libarrow_dataset.a"
    "${ARROW_LIB_DIR}/libparquet.a"
)

#if(UNIX AND NOT APPLE)
#    find_library(CURL_LIB curl)
#    find_library(OPENSSL_SSL_LIB ssl)
#    find_library(OPENSSL_CRYPTO_LIB crypto)
#    find_library(PTHREAD_LIB pthread)
#    find_library(DL_LIB dl)
#    set(SYSTEM_LIBS ${CURL_LIB} ${OPENSSL_SSL_LIB} ${OPENSSL_CRYPTO_LIB} ${PTHREAD_LIB} ${DL_LIB})
#endif()

set(DUCKDB_CUSTOM_LIBRARIES ${ARROW_LIBS}) # ${SYSTEM_LIBS})

log_stage("Declaring DuckDB")
#if (LOAD_TESTS)  # DuckDB sql logical tests
#    set(BUILD_UNITTESTS ON CACHE BOOL "")
#else()
#    set(BUILD_UNITTESTS OFF CACHE BOOL "")
#endif()
set(ENABLE_SANITIZER OFF CACHE BOOL "")
set(ENABLE_UBSAN OFF CACHE BOOL "")
set(DISABLE_VPTR_SANITIZER ON CACHE BOOL "")

FetchContent_Declare(
    duckdb
    GIT_REPOSITORY https://github.com/duckdb/duckdb.git
    GIT_TAG v1.3.2
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
)
log_done()

log_stage("Building DuckDB")
FetchContent_MakeAvailable(duckdb)

log_done()

# Final build steps (DuckDB + extensions) is configured in config/CMakeLists.txt
