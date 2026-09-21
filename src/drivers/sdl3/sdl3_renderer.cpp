#include "sdl3_renderer.hpp"

#include <iostream>
#include <string>
#include "SDL3/SDL_render.h"
#include "SDL3/SDL_surface.h"
#include "SDL3/SDL_video.h"
#include "core/application.hpp"
#include "sdl3_window.hpp"

SDL3Texture::SDL3Texture() {}

SDL3Texture::~SDL3Texture() {
    if (texture != nullptr) {
        SDL_DestroyTexture(texture);
    }
}

void SDL3Texture::loadFromFile(std::string_view path) {
    std::cout << path << std::endl;
    if (!renderer) {
        std::cerr << "error: failed to create texture: sdl3 renderer not found" << std::endl;
        return;
    }

    SDL_Surface* image = SDL_LoadPNG(std::string(path).c_str());
    if (image == nullptr) {
        std::cerr << "error: failed to load png: " << SDL_GetError() << std::endl;
        return;
    }

    texture = SDL_CreateTextureFromSurface(renderer, image);
    if (texture == nullptr) {
        std::cerr << "error: failed to create texture: " << SDL_GetError() << std::endl;
        SDL_DestroySurface(image);
        return;
    }

    SDL_DestroySurface(image);
}

Vector2i SDL3Texture::getSize() const {
    if (texture) {
        float w = 0.0;
        float h = 0.0;
        SDL_GetTextureSize(texture, &w, &h);
        return {static_cast<int32_t>(w), static_cast<int32_t>(h)};
    } else {
        return {0, 0};
    }
}

SDL3Renderer::SDL3Renderer(const SDL3Window& window, const char* driver) {
    renderer = SDL_CreateRenderer(window.window, driver);
    if (renderer == nullptr) {
        std::cerr << "sdl create renderer err: " << SDL_GetError() << std::endl;
        std::exit(1);
    }

    SDL_SetWindowSurfaceVSync(window.window, SDL_WINDOW_SURFACE_VSYNC_DISABLED);
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
    if (letterboxSize.x != 0 && letterboxSize.y != 0) {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        drawRect({0, 0, static_cast<float64_t>(letterboxSize.x), static_cast<float64_t>(letterboxSize.y)}, clearColor);
    } else {
        SDL_SetRenderDrawColor(renderer, clearColor.r, clearColor.g, clearColor.b, clearColor.a);
        SDL_RenderClear(renderer);
    }
}

void SDL3Renderer::swapBuffers() {
    SDL_RenderPresent(renderer);
}

void SDL3Renderer::setLetterboxSize(Vector2i size) {
    SDL_SetRenderLogicalPresentation(renderer, size.x, size.y, SDL_LOGICAL_PRESENTATION_LETTERBOX);
    letterboxSize = size;
}

void SDL3Renderer::drawRect(const Vector4 rectangle, const Color8 color) {
	const SDL_FRect sdlRectangle = {static_cast<float>(rectangle.x), static_cast<float>(rectangle.y), static_cast<float>(rectangle.z), static_cast<float>(rectangle.w)};
	SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
	SDL_RenderFillRect(renderer, &sdlRectangle);
}

void SDL3Renderer::drawTexture(std::shared_ptr<Texture> texture, const Vector4 rectangle, const Color8 tint) {
    SDL3Texture* sdlTexture = dynamic_cast<SDL3Texture*>(texture.get());
    if (!sdlTexture) {
        std::cerr << "error: failed to draw texture: invalid texture" << std::endl;
        return;
    }

    const SDL_FRect sdlRectangle = {static_cast<float>(rectangle.x), static_cast<float>(rectangle.y), static_cast<float>(rectangle.z), static_cast<float>(rectangle.w)};
    SDL_SetRenderDrawColor(renderer, tint.r, tint.g, tint.b, tint.a);
    SDL_RenderTexture(renderer, sdlTexture->texture, nullptr, &sdlRectangle);
}

std::shared_ptr<Texture> SDL3Renderer::newTexture() {
    std::shared_ptr<SDL3Texture> texture = std::make_shared<SDL3Texture>();
    texture->renderer = renderer;
    return texture;
}
