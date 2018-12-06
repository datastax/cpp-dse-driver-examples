cmake_minimum_required(VERSION 2.6.4)

include(FindPackageHandleStandardArgs)

# C/C++ DSE driver dependency
set(_LIBDSE_ROOT_PATHS "${PROJECT_SOURCE_DIR}/lib/dse/")
set(_LIBDSE_ROOT_HINTS ${LIBDSE_ROOT_DIR} $ENV{LIBDSE_ROOT_DIR})
if(NOT WIN32)
  set(_LIBDSE_ROOT_PATHS "${_LIBDSE_ROOT_PATHS}" "/usr/" "/usr/local/")
endif()
set(_LIBDSE_ROOT_HINTS_AND_PATHS HINTS
  HINTS ${_LIBDSE_ROOT_HINTS}
  PATHS ${_LIBDSE_ROOT_PATHS})

find_path(LIBDSE_INCLUDE_DIR
  NAMES dse.h dse/cassandra.h
  HINTS ${_LIBDSE_INCLUDEDIR} ${_LIBDSE_ROOT_HINTS_AND_PATHS}
  PATH_SUFFIXES include)
find_library(LIBDSE_LIBRARY
  NAMES dse libdse
  HINTS ${_LIBDSE_LIBDIR} ${_LIBDSE_ROOT_HINTS_AND_PATHS}
  PATH_SUFFIXES lib)

find_package_handle_standard_args(DSE "Could NOT find the C/C++ DSE driver, try to set the path to the C/C++ DSE driver root folder in the system variable LIBDSE_ROOT_DIR"
  LIBDSE_LIBRARY
  LIBDSE_INCLUDE_DIR)

# Libuv dependency
set(_LIBUV_ROOT_PATHS "${PROJECT_SOURCE_DIR}/lib/libuv/")
set(_LIBUV_ROOT_HINTS ${LIBUV_ROOT_DIR} $ENV{LIBUV_ROOT_DIR})
if(NOT WIN32)
  set(_LIBUV_ROOT_PATHS "${_LIBUV_ROOT_PATHS}" "/usr/" "/usr/local/")
endif()
set(_LIBUV_ROOT_HINTS_AND_PATHS HINTS
  HINTS ${_LIBUV_ROOT_HINTS}
  PATHS ${_LIBUV_ROOT_PATHS})

find_path(LIBUV_INCLUDE_DIR
  NAMES uv.h
  HINTS ${_LIBUV_INCLUDEDIR} ${_LIBUV_ROOT_HINTS_AND_PATHS}
  PATH_SUFFIXES include)
find_library(LIBUV_LIBRARY
  NAMES uv libuv
  HINTS ${_LIBUV_LIBDIR} ${_LIBUV_ROOT_HINTS_AND_PATHS}
  PATH_SUFFIXES lib)
find_package_handle_standard_args(Libuv "Could NOT find libuv, try to set the path to the libuv root folder in the system variable LIBUV_ROOT_DIR"
  LIBUV_LIBRARY
  LIBUV_INCLUDE_DIR)

# OpenSSL dependency
set(OPENSSL_ROOT_DIR "${OPENSSL_ROOT_DIR}"
  "${PROJECT_SOURCE_DIR}/lib/openssl/"
  "$ENV{OPENSSL_ROOT_DIR}")
if(NOT WIN32)
  set(OPENSSL_ROOT_DIR "${OPENSSL_ROOT_DIR}"
    "/usr/"
    "/usr/local/")
endif()
find_package(OpenSSL REQUIRED)

# Create a dummy "dse" dependency that points to the external library
add_library(dse UNKNOWN IMPORTED)
set_property(TARGET dse PROPERTY IMPORTED_LOCATION "${LIBDSE_LIBRARY}")
set(PROJECT_LIB_NAME_TARGET "dse")

LIST(APPEND INCLUDES ${LIBDSE_INCLUDE_DIR})
LIST(APPEND INCLUDES ${LIBDSE_INCLUDE_DIR}/dse)
LIST(APPEND INCLUDES ${LIBUV_INCLUDE_DIR})
LIST(APPEND INCLUDES ${OPENSSL_INCLUDE_DIR})

# Macro to add example sub directories
macro(AddExamples examples_dir)
  file(GLOB EXAMPLES_TO_BUILD "${examples_dir}/*/CMakeLists.txt")
  foreach(example ${EXAMPLES_TO_BUILD})
    get_filename_component(exdir ${example} PATH)
    add_subdirectory(${exdir})
  endforeach()
endmacro()

add_subdirectory(core)
add_subdirectory(dse)
