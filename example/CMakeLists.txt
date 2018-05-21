
# Required CMake
cmake_minimum_required(VERSION 3.2.3)

# Include file with required functions
include(../CXXModules.cmake)

# Use special function for creating C++ modules library.
# Same as add_library but also creates interface files
# and add required flags for current compiler
add_module_library(hello_world
    hello_world.cpp
)

# Create executable target
add_module_executable(main
    main.cpp
)

# Link C++ modules library to the executable
target_link_module_libraries(main hello_world)
