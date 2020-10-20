cmake_minimum_required(VERSION 3.15.0)

include(${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/QtAutoDetect.cmake)

project(Qt
    VERSION 6.0.0
    DESCRIPTION "Qt Libraries"
    HOMEPAGE_URL "https://qt.io/"
    LANGUAGES CXX C ASM
)

# Required so we can call ctest from the root build directory
set_property(GLOBAL PROPERTY CTEST_TARGETS_ADDED 1)
enable_testing()

set(qt_module_prop_prefix "__qt_prop_")
function(extract_projects out_project_list)
    set(project_list "")
    FILE(GLOB directories LIST_DIRECTORIES true RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)
    foreach(directory IN LISTS directories)
        if(NOT IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${child})
            continue()
        endif()
        if(directory STREQUAL "qt5")
            continue()
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${directory}/CMakeLists.txt)
            list(APPEND project_list "${directory}")
        endif()
    endforeach()
    set(${out_project_list} ${project_list} PARENT_SCOPE)
endfunction()

# Also make sure the CMake config files do not recreate the already-existing targets
if (NOT QT_BUILD_STANDALONE_TESTS)
    set(QT_NO_CREATE_TARGETS TRUE)
endif()
set(QT_SUPERBUILD TRUE)

# Get submodules list
extract_projects(subprojects_list)
execute_process(COMMAND "/usr/bin/ruby" "dependencies.rb" "${subprojects_list}"
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE dependencies_error
                OUTPUT_VARIABLE subproject_list_ordered
                OUTPUT_STRIP_TRAILING_WHITESPACE)

if(NOT dependencies_error STREQUAL "0")
    message(FATAL_ERROR "Error ${dependencies_error} ordering dependencies: ${subproject_list_ordered}")
endif()

foreach(project IN LISTS subproject_list_ordered)
    if(project STREQUAL "qtbase")
        if (NOT QT_BUILD_STANDALONE_TESTS)
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake")
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/3rdparty/extra-cmake-modules/find-modules")
            list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qtbase/cmake/3rdparty/kwin")
        endif()
    endif()
    message(DEBUG "Adding '${project}'")
    add_subdirectory(${project})

    if(project STREQUAL "qtbase")
        if (NOT QT_BUILD_STANDALONE_TESTS)
            list(APPEND CMAKE_PREFIX_PATH "${QtBase_BINARY_DIR}/lib/cmake")
            list(APPEND CMAKE_FIND_ROOT_PATH "${QtBase_BINARY_DIR}")
        endif()
    endif()
endforeach()

# Check for unmet dependencies
foreach(project IN LISTS subproject_list_ordered)
    foreach(dep IN LISTS "${qt_module_prop_prefix}${project}_depends")
        if (dep STREQUAL qtbase)
            # Always available skip
            continue()
        endif()
        if (DEFINED BUILD_${module} AND BUILD_${module})
            if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dep}/CMakeLists.txt")
                message(FATAL_ERROR "Module '${project} depends on '${dep}', but ${deps}'s CMakeLists.txt couldn't be found.\n")
            endif()
            if(NOT BUILD_${dep})
                message(FATAL_ERROR "Module '${project} depends on '${dep}', but ${deps} will not be built.\n")
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
