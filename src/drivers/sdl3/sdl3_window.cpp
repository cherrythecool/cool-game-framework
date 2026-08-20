#include "sdl3_window.hpp"

#include <iostream>

SDL3Window::SDL3Window(const char* title, const Vector2i size, const WindowFlags flags) : Window(title, size, flags) {
    SDL_WindowFlags sdlFlags = 0;

    if (flags.resizable) {
        sdlFlags |= SDL_WINDOW_RESIZABLE;
    }

    window = SDL_CreateWindow(title, size.x, size.y, sdlFlags);
    if (window == nullptr) {
        std::cerr << "sdl create window err: " << SDL_GetError() << std::endl;
        std::exit(1);
    }
}

SDL3Window::~SDL3Window() {
    if (window != nullptr) {
        SDL_DestroyWindow(window);
    }
}

void SDL3Window::setTitle(const char* title) {
    SDL_SetWindowTitle(window, title);
}

void SDL3Window::setSize(const Vector2i size) {
    SDL_SetWindowSize(window, size.x, size.y);
}

void SDL3Window::setFullscreen(const bool fullscreen) {
    SDL_SetWindowFullscreen(window, fullscreen);
}

std::string_view SDL3Window::getTitle() const {
    return std::string_view(SDL_GetWindowTitle(window));
}

Vector2i SDL3Window::getSize() const {
    Vector2i size;
    SDL_GetWindowSize(window, &size.x, &size.y);
    return size;
}

bool SDL3Window::getFullscreen() const {
    return SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN;
}