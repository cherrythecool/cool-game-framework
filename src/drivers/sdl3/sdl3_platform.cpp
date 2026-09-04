#include "sdl3_platform.hpp"

#include <iostream>

#include "SDL3/SDL.h"
#include "SDL3/SDL_events.h"
#include "core/input_event.hpp"
#include "core/time_constants.hpp"

SDL3Platform::SDL3Platform() {
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        std::cerr << "sdl init err: " << SDL_GetError() << std::endl;
        std::exit(1);
    }
}

SDL3Platform::~SDL3Platform() {
    SDL_Quit();
}

std::optional<InputEvent> SDL3Platform::pollEvent() {
    SDL_Event event;
    SDL_PollEvent(&event);

    switch (event.type) {
        case SDL_EVENT_QUIT:
            hasRequestedClose = true;
            break;
        case SDL_EVENT_KEY_DOWN:
        case SDL_EVENT_KEY_UP:
            KeyboardEvent keyEvent = {
                Keycode(event.key.key),
                event.key.repeat,
            };

            return std::make_optional(InputEvent {
                event.type == SDL_EVENT_KEY_DOWN,
                InputEventType::KEYBOARD,
                keyEvent,
            });

            break;
    }

    return {};
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