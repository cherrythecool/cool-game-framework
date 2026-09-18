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

    src/core/assets/texture_loader.cpp

    src/drivers/sdl3/sdl3_platform.cpp
    src/drivers/sdl3/sdl3_window.cpp
    src/drivers/sdl3/sdl3_renderer.cpp

    src/scene/object.cpp
    src/scene/color_rect.cpp
    src/scene/sprite_2d.cpp
)

target_include_directories(cgf PUBLIC src/)

target_link_libraries(cgf PUBLIC SDL3::SDL3)

# asset shiz
add_custom_command(
    TARGET cgf POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/assets"
            "$<TARGET_FILE_DIR:cgf>/assets"
    COMMENT "Copying assets folder to the executable directory..."
)