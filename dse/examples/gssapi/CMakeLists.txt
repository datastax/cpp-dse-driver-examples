##
# Copyright (c) DataStax, Inc.
#
# This software can be used solely with DataStax Enterprise. Please consult the
# license at http://www.datastax.com/terms/datastax-dse-driver-license-terms
##
cmake_minimum_required(VERSION 2.6.4)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ".")

# Set up rules/commands for building gssapi example
set(PROJECT_EXAMPLE_NAME gssapi)
set(EXAMPLE_SRC_FILES ${PROJECT_SOURCE_DIR}/examples/gssapi/gssapi.c)
include_directories(${INCLUDES})
add_executable(${PROJECT_EXAMPLE_NAME} ${EXAMPLE_SRC_FILES})
target_link_libraries(${PROJECT_EXAMPLE_NAME} ${PROJECT_LIB_NAME_TARGET} ${DSE_LIBS})
add_dependencies(${PROJECT_EXAMPLE_NAME} ${PROJECT_LIB_NAME_TARGET})

set_property(
  TARGET ${PROJECT_EXAMPLE_NAME}
  APPEND PROPERTY COMPILE_FLAGS ${EXAMPLE_C_FLAGS})
set_property(TARGET ${PROJECT_EXAMPLE_NAME} PROPERTY FOLDER "Examples")

# Set up rules/commands for building gssapi_proxy example
set(PROJECT_EXAMPLE_NAME gssapi_proxy)
set(EXAMPLE_SRC_FILES ${PROJECT_SOURCE_DIR}/examples/gssapi/gssapi_proxy.c)
add_executable(${PROJECT_EXAMPLE_NAME} ${EXAMPLE_SRC_FILES})
target_link_libraries(${PROJECT_EXAMPLE_NAME} ${PROJECT_LIB_NAME_TARGET} ${DSE_LIBS})
add_dependencies(${PROJECT_EXAMPLE_NAME} ${PROJECT_LIB_NAME_TARGET})

set_property(
        TARGET ${PROJECT_EXAMPLE_NAME}
        APPEND PROPERTY COMPILE_FLAGS ${EXAMPLE_C_FLAGS})
set_property(TARGET ${PROJECT_EXAMPLE_NAME} PROPERTY FOLDER "Examples")
