cmake_minimum_required(VERSION 2.6.4)

project("Core Examples")

set(CASS_ROOT_DIR ${PROJECT_SOURCE_DIR})
set(CASS_LIBS ${LIBUV_LIBRARY})
AddExamples("examples")
