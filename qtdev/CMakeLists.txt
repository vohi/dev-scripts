cmake_minimum_required(VERSION 3.15.0)

include(${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/QtAutoDetect.cmake)

project(Qt
    VERSION 6.0.0
    DESCRIPTION "Qt Libraries"
    HOMEPAGE_URL "https://qt.io/"
    LANGUAGES CXX C ASM
)

# Required so we can call ctest from the root build directory
enable_testing()

set(qt_module_prop_prefix "__qt_prop_")

# Also make sure the CMake config files do not recreate the already-existing targets
if (NOT QT_BUILD_STANDALONE_TESTS)
    set(QT_NO_CREATE_TARGETS TRUE)
endif()
set(QT_SUPERBUILD TRUE)

# Populates $out_module_list with all subdirectories that have a CMakeLists.txt file
function(extract_modules out_module_list)
    set(module_list "")
    FILE(GLOB directories LIST_DIRECTORIES true RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)
    foreach(directory IN LISTS directories)
        if(NOT IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${directory})
            continue()
        endif()
        if(directory STREQUAL "qt5")
            continue()
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${directory}/CMakeLists.txt)
            list(APPEND module_list "${directory}")
        endif()
    endforeach()
    set(${out_module_list} ${module_list} PARENT_SCOPE)
endfunction()

function(parse_dependencies depends_file out_dependencies)
    file(STRINGS ${depends_file} lines)
    # poor man's yaml parser, populating $dependencies with all dependencies
    set(dependencies "")
    foreach(line IN LISTS lines)
        if(line STREQUAL "dependencies:")
            set(FOUND_dependencies 1)
        endif()
        if(NOT FOUND_dependencies)
            continue()
        endif()
        if(line MATCHES "^  (.*):$")
            set(dependency ${CMAKE_MATCH_1})
            # dependencies are specified with relative path to this module
            string(REPLACE "../" "" dependency ${dependency})
            list(APPEND dependencies ${dependency})
        endif()
    endforeach()
    set(${out_dependencies} ${dependencies} PARENT_SCOPE)
endfunction()

# Load $module and populate $out_ordered with the submodules based on their dependencies
# $ordered carries already sorted dependencies; $out_has_dependencies is left empty
# if there are no dependencies, otherwise set to 1
# Function calls itself recursively if a dependency is found that is not yet in $ordered.
function(load_module module ordered out_ordered out_has_dependencies)
    set(depends_file "${CMAKE_CURRENT_SOURCE_DIR}/${module}/dependencies.yaml")
    if(NOT EXISTS ${depends_file})
        set(${out_has_dependencies} "" PARENT_SCOPE)
        return()
    endif()
    set(${out_has_dependencies} "1" PARENT_SCOPE)
    set(dependencies "")
    parse_dependencies(${depends_file} dependencies)
    # module hasn't been seen yet, append it
    list(FIND ordered "${module}" pindex)
    if (pindex EQUAL -1)
        list(LENGTH ordered pindex)
        list(APPEND ordered ${module})
    endif()
    foreach(dependency IN LISTS dependencies)
        list(FIND ordered "${dependency}" dindex)
        if (dindex EQUAL -1)
            # dependency hasnt' been seen yet - load it
            list(INSERT ordered ${pindex} ${dependency})
            load_module(${dependency} "${ordered}" ordered has_dependency)
        elseif(dindex GREATER pindex)
            # otherwise, make sure it is before module
            list(REMOVE_AT ordered ${dindex})
            list(INSERT ordered ${pindex} ${dependency})
        endif()
    endforeach()
    set(${out_ordered} ${ordered} PARENT_SCOPE)
endfunction()

function(order_modules modules out_all_ordered)
    set(ordered "")
    set(no_dependencies "")
    foreach(module IN LISTS modules)
        set(out_ordered "")
        load_module(${module} "${ordered}" out_ordered module_depends)
        if(NOT module_depends)
            list(APPEND no_dependencies ${module})
        endif()
        set(ordered "${out_ordered}")
    endforeach()
    list(APPEND ordered "${no_dependencies}")
    set(${out_all_ordered} ${ordered} PARENT_SCOPE)
endfunction()

# Get submodule list if not already defined
if (NOT BUILD_SUBMODULES)
    extract_modules(BUILD_SUBMODULES)
endif()

order_modules("${BUILD_SUBMODULES}" BUILD_SUBMODULES)

foreach(module IN LISTS BUILD_SUBMODULES)
    if(module STREQUAL "qtbase")
        if (NOT QT_BUILD_STANDALONE_TESTS)
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake")
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/3rdparty/extra-cmake-modules/find-modules")
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/3rdparty/kwin")
        endif()
    endif()
    message(DEBUG "Adding '${module}'")
    add_subdirectory(${module})

    if(module STREQUAL "qtbase")
        if (NOT QT_BUILD_STANDALONE_TESTS)
            list(APPEND CMAKE_PREFIX_PATH "${QtBase_BINARY_DIR}/lib/cmake")
            list(APPEND CMAKE_FIND_ROOT_PATH "${QtBase_BINARY_DIR}")
        endif()
    endif()
endforeach()

# Check for unmet dependencies
foreach(module IN LISTS BUILD_SUBMODULES)
    add_custom_target(${module}_src COMMAND ${CMAKE_COMMAND} --build . --parallel --target ${module}/src/all USES_TERMINAL)
    add_custom_target(${module}_all COMMAND ${CMAKE_COMMAND} --build . --parallel --target ${module}/all USES_TERMINAL)
    add_custom_target(${module}_clean COMMAND ${CMAKE_COMMAND} --build . --parallel --target ${module}/clean USES_TERMINAL)
    foreach(dep IN LISTS "${qt_module_prop_prefix}${module}_depends")
        if (dep STREQUAL qtbase)
            # Always available skip
            continue()
        endif()
        if (DEFINED BUILD_${module} AND BUILD_${module})
            if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dep}/CMakeLists.txt")
                message(FATAL_ERROR "Module '${module} depends on '${dep}', but ${deps}'s CMakeLists.txt couldn't be found.\n")
            endif()
            if(NOT BUILD_${dep})
                message(FATAL_ERROR "Module '${module} depends on '${dep}', but ${deps} will not be built.\n")
            endif()
        endif()
    endforeach()
endforeach()


if(NOT QT_BUILD_STANDALONE_TESTS)
    # Display a summary of everything
    include(QtBuildInformation)
    qt_print_feature_summary()
    qt_print_build_instructions()
endif()
