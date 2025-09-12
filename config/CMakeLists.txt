# =============================================
# Build Targets
# =============================================

file(GLOB_RECURSE EXTENSION_SOURCES CONFIGURE_DEPENDS "${EXTENSION_ROOT_DIR}/src/*.cpp")

log_stage("Building static extension")
build_static_extension(duckdb_graphar ${EXTENSION_SOURCES})
log_done()

log_stage("Building loadable extension")
build_loadable_extension(duckdb_graphar ${EXTENSION_SOURCES})
log_done()

set(DEPS_INSTALL_DIR ${CMAKE_BINARY_DIR}/_deps)
set(ARROW_INSTALL_DIR ${DEPS_INSTALL_DIR}/arrow-install)
set(GRAPHAR_INSTALL_DIR ${DEPS_INSTALL_DIR}/graphar-install)

set(GRAPHAR_SOURCE_DIR ${DEPS_INSTALL_DIR}/graphar-src)

set(EXTENSION_INCLUDES
    $<BUILD_INTERFACE:${EXTENSION_ROOT_DIR}/include>
    $<BUILD_INTERFACE:${GRAPHAR_INSTALL_DIR}/include>
    $<BUILD_INTERFACE:${GRAPHAR_SOURCE_DIR}/cpp/thirdparty>
    $<BUILD_INTERFACE:${duckdb_SOURCE_DIR}/src/include>
    $<BUILD_INTERFACE:${arrow_SOURCE_DIR}/cpp/src>
)

target_include_directories(duckdb_graphar_extension PUBLIC ${EXTENSION_INCLUDES} $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_include_directories(duckdb_graphar_loadable_extension PUBLIC ${EXTENSION_INCLUDES} $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

set(EXT_LIBS
    graphar::graphar_static
    arrow::arrow_static
    "${ARROW_LIB_DIR}/libarrow_acero.a"
    "${ARROW_LIB_DIR}/libarrow_bundled_dependencies.a"
    "${ARROW_LIB_DIR}/libarrow_dataset.a"
    "${ARROW_LIB_DIR}/libparquet.a"
)

find_library(CURL_LIB curl)
list(APPEND EXT_LIBS ${CURL_LIB})

#####
add_custom_target(list_dirs
    COMMAND ${CMAKE_COMMAND} -E echo "Directory structure -->:"
    COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR} find . -type d -print | sort
    COMMENT "Listing all directories"
    VERBATIM
)
#####


#find_library(CURL_LIB curl)
#find_library(SSL_LIB ssl)
#find_library(CRYPTO_LIB crypto)
#find_library(THRIFT_LIB thrift)
#find_library(ARROW_ACERO_LIB arrow_acero PATHS ${ARROW_LIB_DIR} NO_DEFAULT_PATH)
#find_library(ARROW_COMPUTE_LIB arrow_compute PATHS ${ARROW_LIB_DIR} NO_DEFAULT_PATH)
#find_library(ARROW_UTIL_LIB arrow_util PATHS ${ARROW_LIB_DIR} NO_DEFAULT_PATH)
#find_library(DL_LIB dl)
#find_library(PTHREAD_LIB pthread)
#find_library(RT_LIB rt)
#find_library(Z_LIB z)
#find_library(LZ4_LIB lz4)
#find_library(SNAPPY_LIB snappy)
#find_library(ZSTD_LIB zstd)
#find_library(RE2_LIB re2)
#find_library(URIPARSER_LIB uriparser)
#find_library(DOUBLE_CONVERSION_LIB double-conversion)
#find_library(UTF8PROC_LIB utf8proc)

#foreach(LIB ${CURL_LIB} ${SSL_LIB} ${CRYPTO_LIB} ${THRIFT_LIB}
#            ${ARROW_ACERO_LIB} ${ARROW_COMPUTE_LIB} ${ARROW_UTIL_LIB}
#            ${DL_LIB} ${PTHREAD_LIB} ${RT_LIB} ${Z_LIB}
#            ${LZ4_LIB} ${SNAPPY_LIB} ${ZSTD_LIB}
#            ${BROTLI_COMMON_LIB} ${BROTLI_DEC_LIB} ${BROTLI_ENC_LIB}
#            ${RE2_LIB} ${URIPARSER_LIB} ${DOUBLE_CONVERSION_LIB} ${UTF8PROC_LIB})
#    if(LIB)
#        list(APPEND EXT_LIBS ${LIB})
#    endif()
#endforeach()

if(APPLE)
    list(APPEND EXT_LIBS
        "-framework CoreFoundation"
        "-framework Security"
        "-framework SystemConfiguration"
        "-framework Accelerate"
    )
else()
    # Linux-specific libraries
    find_library(OPENSSL_SSL_LIB ssl)
    list(APPEND EXT_LIBS ${OPENSSL_SSL_LIB})

    find_library(OPENSSL_CRYPTO_LIB crypto)
    list(APPEND EXT_LIBS ${OPENSSL_CRYPTO_LIB})

    find_library(THRIFT_LIB thrift)
    list(APPEND EXT_LIBS ${THRIFT_LIB})

    list(APPEND EXT_LIBS
        "${ARROW_LIB_DIR}/libarrow_acero.a"
        "${ARROW_LIB_DIR}/libarrow_bundled_dependencies.a"
        "${ARROW_LIB_DIR}/libarrow_dataset.a"
        "${ARROW_LIB_DIR}/libparquet.a"
    )
endif()

target_link_libraries(duckdb_graphar_extension
    duckdb_static
    ${EXT_LIBS}
)

target_link_libraries(duckdb_graphar_loadable_extension
    ${EXT_LIBS}
)

# =============================================
# Installation
# =============================================
log_stage("Installing...")
set(INSTALL_LIB_DIR "${CMAKE_INSTALL_LIBDIR}" CACHE PATH "Library installation directory")

install(
  TARGETS duckdb_graphar_extension
  EXPORT "${DUCKDB_EXPORT_SET}"
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}")

install(TARGETS duckdb_graphar_loadable_extension
    LIBRARY DESTINATION ${INSTALL_LIB_DIR}
)

install(DIRECTORY include/ DESTINATION include
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)

log_done()
