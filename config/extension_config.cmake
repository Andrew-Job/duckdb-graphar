# Configuration for the DuckDB 'duckdb_graphar' extension.
#

duckdb_extension_load(duckdb_graphar
    SOURCE_DIR "${EXTENSION_ROOT_DIR}/config"
    INCLUDE_DIR "${EXTENSION_ROOT_DIR}/include"
    LINKED_LIBS "arrow;graphar"
    LOAD_TESTS
if(APPLE)
    INSTALL_RPATH "@loader_path"
else()
    INSTALL_RPATH "\$ORIGIN"
endif()
    BUILD_WITH_INSTALL_RPATH FALSE
)
