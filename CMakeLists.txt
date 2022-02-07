cmake_minimum_required(VERSION 3.17)
project(ChowDSP-Plugins)

include(ExternalProject)

option(BUILD_CHOWTAPE "Build the ChowTape plugin" ON)
if(BUILD_CHOWTAPE)
    message(STATUS "Configuring build for ChowTape")
    set(CHOWTAPE_DIR "${CMAKE_SOURCE_DIR}/AnalogTapeModel/Plugin")
    ExternalProject_Add(ChowTape_Package
        SOURCE_DIR "${CHOWTAPE_DIR}"
        CMAKE_ARGS "-DBUILD_RELEASE=ON -DCMAKE_BUILD_TYPE=Release"
        STEP_TARGETS build
        EXCLUDE_FROM_ALL TRUE
    )
    add_custom_target(ChowTape ALL)
    add_dependencies(ChowTape ChowTape_Package-build)
endif()

option(BUILD_CHOWMATRIX "Build the ChowMatrix plugin" ON)
if(BUILD_CHOWMATRIX)
    message(STATUS "Configuring build for ChowMatrix")
    set(CHOWMATRIX_DIR "${CMAKE_SOURCE_DIR}/ChowMatrix")
    ExternalProject_Add(ChowMatrix_Package
        SOURCE_DIR "${CHOWMATRIX_DIR}"
        CMAKE_ARGS "-DBUILD_RELEASE=ON -DCMAKE_BUILD_TYPE=Release"
        STEP_TARGETS build
        EXCLUDE_FROM_ALL TRUE
    )
    add_custom_target(ChowMatrix ALL)
    add_dependencies(ChowMatrix ChowMatrix_Package-build)
endif()

option(BUILD_CHOWCENTAUR "Build the KlonCentaur plugin" ON)
if(BUILD_CHOWCENTAUR)
    message(STATUS "Configuring build for KlonCentaur")
    set(CHOWCENTAUR_DIR "${CMAKE_SOURCE_DIR}/KlonCentaur")
    ExternalProject_Add(KlonCentaur_Package
        SOURCE_DIR "${CHOWCENTAUR_DIR}"
        CMAKE_ARGS "-DBUILD_RELEASE=ON -DCMAKE_BUILD_TYPE=Release"
        STEP_TARGETS build
        EXCLUDE_FROM_ALL TRUE
    )
    add_custom_target(KlonCentaur ALL)
    add_dependencies(KlonCentaur KlonCentaur_Package-build)
endif()

option(BUILD_CHOWKICK "Build the ChowKick plugin" ON)
if(BUILD_CHOWKICK)
    message(STATUS "Configuring build for ChowKick")
    set(CHOWKICK_DIR "${CMAKE_SOURCE_DIR}/ChowKick")
    ExternalProject_Add(ChowKick_Package
        SOURCE_DIR "${CHOWKICK_DIR}"
        CMAKE_ARGS "-DBUILD_RELEASE=ON -DCMAKE_BUILD_TYPE=Release"
        STEP_TARGETS build
        EXCLUDE_FROM_ALL TRUE
    )
    add_custom_target(ChowKick ALL)
    add_dependencies(ChowKick ChowKick_Package-build)
endif()

option(BUILD_BYOD "Build the BYOD plugin" OFF)
if(BUILD_BYOD)
    message(STATUS "Configuring build for BYOD")
    set(BYOD_DIR "${CMAKE_SOURCE_DIR}/BYOD")
    ExternalProject_Add(BYOD_Package
        SOURCE_DIR "${BYOD_DIR}"
        CMAKE_ARGS "-DBUILD_RELEASE=ON -DCMAKE_BUILD_TYPE=Release"
        STEP_TARGETS build
        EXCLUDE_FROM_ALL TRUE
    )
    add_custom_target(BYOD ALL)
    add_dependencies(BYOD BYOD_Package-build)
endif()
