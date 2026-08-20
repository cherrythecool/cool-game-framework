#include "sdl3_platform.hpp"

#include <iostream>
#include "SDL3/SDL.h"
#include "time_constants.hpp"

SDL3Platform::SDL3Platform() {
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        std::cerr << "sdl init err: " << SDL_GetError() << std::endl;
        std::exit(1);
    }
}

SDL3Platform::~SDL3Platform() {
    SDL_Quit();
}

void SDL3Platform::pollEvents() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_EVENT_QUIT) {
            hasRequestedClose = true;
        }
    }
}

bool SDL3Platform::requestedClose() {
    return hasRequestedClose;
}

float64_t SDL3Platform::getTimeSeconds() {
    return static_cast<float64_t>(getTimeNS()) / NS_PER_SECOND;
}

uint64_t SDL3Platform::getTimeNS() {
    return SDL_GetTicksNS();
}