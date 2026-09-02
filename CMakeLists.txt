cmake_minimum_required(VERSION 3.10)

project(cgf VERSION 0.0.1)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(SDL_TESTS OFF)
set(SDL_EXAMPLES OFF)
add_subdirectory(vendor/SDL3)

add_executable(cgf
    src/main.cpp

    src/core/application.cpp

    src/drivers/sdl3/sdl3_platform.cpp
    src/drivers/sdl3/sdl3_window.cpp
    src/drivers/sdl3/sdl3_renderer.cpp

    src/scene/object.cpp
    src/scene/color_rect.cpp
)

target_include_directories(cgf PUBLIC src/)

target_link_libraries(cgf PUBLIC SDL3::SDL3)