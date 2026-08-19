cmake_minimum_required(VERSION 3.10)

project(cgf VERSION 0.0.1)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(cgf
    src/main.cpp
)

target_include_directories(cgf PUBLIC src/)