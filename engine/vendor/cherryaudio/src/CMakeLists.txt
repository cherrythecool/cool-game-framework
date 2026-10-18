cmake_minimum_required(VERSION 3.12)

option(OP_DISABLE_HTTP "Disable HTTP support" ON)
option(OP_DISABLE_EXAMPLES "" ON)
option(OP_DISABLE_DOCS "" ON)
set(BUILD_TESTING OFF)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/>")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "$<1:${CMAKE_BINARY_DIR}/>")

set(BUILD_SHARED_LIBS OFF)
set(OPUS_STATIC_RUNTIME ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_subdirectory(vendor/opus-1.5.2)
add_subdirectory(vendor/libogg-1.3.5)
add_subdirectory(vendor/opusfile-master)

project(cherryaudio VERSION 1.1.0)

add_library(${PROJECT_NAME} STATIC cherryaudio.c)
target_link_libraries(${PROJECT_NAME} opus)
target_link_libraries(${PROJECT_NAME} ogg)
target_link_libraries(${PROJECT_NAME} opusfile)

target_include_directories(${PROJECT_NAME} PUBLIC .)
target_include_directories(${PROJECT_NAME} PUBLIC vendor)
