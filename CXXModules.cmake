# ########################################################################## #
# Copyright (c) 2018 Jiří Fatka
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ########################################################################## #

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    # Clang
    set(CXX_MODULES_FLAGS -fmodules-ts)
    set(CXX_MODULES_EXT pcm)
    set(CXX_MODULES_CREATE_FLAGS -fmodules-ts -x c++-module --precompile)
    set(CXX_MODULES_USE_FLAG -fmodule-file)
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    # GCC
    message(FATAL_ERROR "GCC is not supported yet")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    # MSVC
    message(FATAL_ERROR "Visual Compiler is not supported yet")
else ()
    message(FATAL_ERROR "Unsupported compiler")
endif ()

# ########################################################################## #

# Compiler flags support tests
include(CheckCXXCompilerFlag)
include(CMakePushCheckState)

# Check if used compiler version supports modules
check_cxx_compiler_flag(${CXX_MODULES_FLAGS} CXX_MODULES)

# ########################################################################## #

##
## Check if current compiler supports C++ modules. If compiler doesn't support
## modules it fails with fatal error.
##
function (_check_cxx_modules_support)
    if (NOT CXX_MODULES)
        message(FATAL_ERROR "Compiler doesn't support C++ modules (TS)")
    endif ()
endfunction ()

# ########################################################################## #

##
## Enable C++ modules for project.
##
## This function adds appropriate compiler flags to the target.
##
function (target_enable_cxx_modules TARGET)
    _check_cxx_modules_support()

    # Add modules flag
    target_compile_options(${TARGET} PRIVATE ${CXX_MODULES_FLAGS})
endfunction ()

# ########################################################################## #

##
## Create an executable with C++ support
##
function (add_module_executable TARGET)
    _check_cxx_modules_support()

    add_executable(${TARGET} ${ARGN})

    # Enable modules for target
    target_enable_cxx_modules(${TARGET})
endfunction ()

# ########################################################################## #

##
## Create C++ module library.
##
## Sets target property CXX_INTERFACE_FILES
##
function (add_module_library TARGET)
    _check_cxx_modules_support()

    # Get sources
    set(_sources)

    # Filter source files
    foreach (_arg ${ARGN})
        list(FIND "STATIC;SHARED;MODULE;EXCLUDE_FROM_ALL;OBJECT;UNKNOWN;IMPORTED" ${_arg} _skip)

        if (${_skip} GREATER_EQUAL 0)
            continue ()
        endif ()

        if (${_arg} MATCHES "ALIAS")
            message(FATAL_ERROR "Alias library is not supported")
        endif ()

        # TODO: limit sources extensions?

        list(APPEND _sources ${_arg})
    endforeach ()

    # Allow to use CXX compiler on C++ module files
    set_source_files_properties(${_sources} PROPERTIES LANGUAGE CXX)

    # Create normal library
    add_library(${TARGET} ${ARGN})

    # Enable modules for target
    target_enable_cxx_modules(${TARGET})

    set(_interface_files)

    # Create targets for interface files
    foreach (_source ${_sources})
        set(_o_file ${_source}.${CXX_MODULES_EXT})
        set(_i_file ${CMAKE_CURRENT_SOURCE_DIR}/${_source})

        # TODO: CXX flags might be different
        set(_cmd ${CMAKE_CXX_COMPILER} $<TARGET_PROPERTY:${TARGET},COMPILE_OPTIONS> ${CXX_MODULES_CREATE_FLAGS} ${_i_file} -o ${_o_file})

        # Create interface build target
        add_custom_target(${_o_file}
            COMMAND ${_cmd}
            DEPENDS ${_i_file}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        )

        list(APPEND _interface_files ${_o_file})
    endforeach ()

    # Store property with interface files
    set_target_properties(${TARGET}
        PROPERTIES CXX_INTERFACE_FILES "${_interface_files}"
    )
endfunction ()

# ########################################################################## #

##
## Link a (C++ module) library to (C++ module) target.
##
## Sets target property CXX_INTERFACE_FILES
##
function (target_link_module_libraries TARGET)
    _check_cxx_modules_support()

    # Enable modules for target
    target_enable_cxx_modules(${TARGET})

    foreach (_arg ${ARGN})
        list(FIND "PUBLIC;PRIVATE;INTERFACE" ${_arg} _skip)

        if (${_skip} GREATER_EQUAL 0)
            continue ()
        endif ()

        # Get interface files from library
        get_target_property(_interface_files ${_arg} CXX_INTERFACE_FILES)

        foreach (_file ${_interface_files})
            add_dependencies(${TARGET} ${_file})

            # TODO: might be different on different compilers
            target_compile_options(${TARGET} PRIVATE ${CXX_MODULES_USE_FLAG}=${_file})
        endforeach ()
    endforeach ()

    # Normal link
    target_link_libraries(${TARGET} ${ARGN})
endfunction ()

# ########################################################################## #
