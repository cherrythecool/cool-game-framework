#include "sdl3_renderer.hpp"

#include <iostream>
#include "sdl3_window.hpp"

SDL3Renderer::SDL3Renderer(const SDL3Window& window, const char* driver) {
    renderer = SDL_CreateRenderer(window.window, driver);
    if (renderer == nullptr) {
        std::cerr << "sdl create renderer err: " << SDL_GetError() << std::endl;
        std::exit(1);
    }
}

SDL3Renderer::~SDL3Renderer() {
    if (renderer != nullptr) {
        SDL_DestroyRenderer(renderer);
    }
}

void SDL3Renderer::setClearColor(const Color8 clearColor) {
    SDL_SetRenderDrawColor(renderer, clearColor.r, clearColor.g, clearColor.b, clearColor.a);
}

void SDL3Renderer::clear() {
    SDL_RenderClear(renderer);
}

void SDL3Renderer::swapBuffers() {
    SDL_RenderPresent(renderer);
}