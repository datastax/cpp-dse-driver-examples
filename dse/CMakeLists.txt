cmake_minimum_required(VERSION 2.6.4)

project("DSE Examples")

set(DSE_LIBS ${LIBUV_LIBRARY})
AddExamples("examples")
