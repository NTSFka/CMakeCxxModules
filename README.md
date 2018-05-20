# CMake C++ Modules

CMake module for C++ modules TS projects.

## Supported compilers

 * Clang 7
 * [WIP] MSVC 
 * [WIP] GCC

## Usage

Download `CXXModules.cmake` file and include it into your CMake project.

The basic usage is put the file in same directory as `CMakeLists.txt`:

```cmake
include(CMakeModules.cmake)
```

Alternatively the file can stored in a path referenced in `CMAKE_MODULE_PATH` so you can only type:

```cmake
include(CMakeModules)
```

Now you have access to special functions which enable C++ modules support.

 * `target_enable_cxx_modules` - enable C++ modules support for project. It just set compiler options for C++ modules.
 * `add_module_library` - same as CMake's `add_library` but generate C++ module interface files from given source 
   files and store that in `CXX_INTERFACE_FILES` target property.
 * `add_module_executable` - same as `add_executable` but enable C++ modules support.
 * `target_link_module_libraries` - same as `target_link_libraries` but generate C++ modules interface files import
   flags for target.

## Example

```cmake
# Required CMake
cmake_minimum_required(VERSION 3.2.3)

# Include file with required functions
include(CXXModules.cmake)

# Use special function for creating C++ modules library.
# Same as add_library but also creates interface files
# and add required flags for current compiler
add_module_library(hello_world
    hello_world.cppm
)

# Create executable target
add_module_executable(main
    main.cpp
)

# Link C++ modules library to the executable
target_link_module_libraries(main hello_world)
```
