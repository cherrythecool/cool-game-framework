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
	this->clearColor = clearColor;
}

void SDL3Renderer::clear() {
	SDL_SetRenderDrawColor(renderer, clearColor.r, clearColor.g, clearColor.b, clearColor.a);
    SDL_RenderClear(renderer);
}

void SDL3Renderer::swapBuffers() {
    SDL_RenderPresent(renderer);
}

void SDL3Renderer::drawRect(const Vector4 rectangle, const Color8 color) {
	const SDL_FRect sdlRectangle = {static_cast<float>(rectangle.x), static_cast<float>(rectangle.y), static_cast<float>(rectangle.z), static_cast<float>(rectangle.w)};
	SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
	SDL_RenderFillRect(renderer, &sdlRectangle);
}
