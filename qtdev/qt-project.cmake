macro(qt_project template qt)
    get_filename_component(name ${CMAKE_CURRENT_LIST_DIR} NAME)
    set(CMAKE_INCLUDE_CURRENT_DIR ON)
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)

    file(GLOB_RECURSE source_files
         RELATIVE ${CMAKE_CURRENT_LIST_DIR} CONFIGURE_DEPENDS
         "*.cpp"
        )
    file(GLOB_RECURSE header_files
         RELATIVE ${CMAKE_CURRENT_LIST_DIR} CONFIGURE_DEPENDS
         "*.h"
        )

    set(template ${template}) # why?!
    list(APPEND qt_modules "${qt}")

    list(APPEND all_files ${source_files})
    list(APPEND all_files ${header_files})

    # remove CMake-generated files
    file(RELATIVE_PATH buildDir ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_BINARY_DIR})
    list(FILTER all_files EXCLUDE REGEX "${buildDir}/*")

    if (template STREQUAL "app")
        add_executable( ${name} ${all_files})
    elseif (template STREQUAL "lib")
        add_executable( ${library} ${all_files})
    else()
        message("Don't know how to build '${name}' with template '${template}'")
    endif()

    foreach(qt_module IN LISTS qt_modules)
        find_package(Qt6 COMPONENTS "${qt_module}")
        target_link_libraries(${name} PUBLIC "Qt::${qt_module}")
    endforeach()
endmacro()
