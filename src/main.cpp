#include <iostream>

#include "SDL3/SDL.h"

#include "color.hpp"
#include "vectors.hpp"
#include "platform.hpp"
#include "window.hpp"
#include "renderer.hpp"

#include "drivers/sdl3/sdl3_platform.hpp"
#include "drivers/sdl3/sdl3_window.hpp"
#include "drivers/sdl3/sdl3_renderer.hpp"

int main(void) {
    SDL3Platform platform = SDL3Platform();
    SDL3Window window = SDL3Window("cool game!", {800, 600}, {});
    SDL3Renderer renderer = SDL3Renderer(window);

    uint64_t start = SDL_GetTicksNS();
    uint64_t frames = 0;

    while (!platform.requestedClose()) {
        platform.pollEvents();

        frames++;
        if (SDL_GetTicksNS() - start >= 1000000000) {
            std::cout << frames << " FPS\n";
            frames = 0;
            start = SDL_GetTicksNS();
        }

        renderer.setClearColor({77, 77, 77});
        renderer.clear();
        renderer.swapBuffers();
    }

    return 0;
}