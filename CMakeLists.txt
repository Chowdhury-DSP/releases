cmake_minimum_required(VERSION 3.17)
project(ChowDSP-Plugins)

include(ExternalProject)

option(BUILD_BYOD "Build the BYOD plugin" ON)
if(BUILD_BYOD)
    message(STATUS "Configuring build for BYOD")
    set(BYOD_DIR "${CMAKE_SOURCE_DIR}/plugins/BYOD/BYOD")
    ExternalProject_Add(BYOD_Package
        SOURCE_DIR "${BYOD_DIR}"
        # BINARY_DIR "${BYOD_DIR}/build"
        CMAKE_ARGS "-DBUILD_RELEASE=ON"
    )
endif()

option(BUILD_CHOWKICK "Build the ChowKick plugin" ON)
if(BUILD_CHOWKICK)
    message(STATUS "Configuring build for ChowKick")
    set(CHOWKICK_DIR "${CMAKE_SOURCE_DIR}/plugins/ChowKick/ChowKick")
    ExternalProject_Add(ChowKick_Package
        SOURCE_DIR "${CHOWKICK_DIR}"
        # BINARY_DIR "${CHOWKICK_DIR}/build"
        CMAKE_ARGS ""
    )
endif()
