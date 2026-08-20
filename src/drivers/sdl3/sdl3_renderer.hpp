#pragma once

#include "core/renderer.hpp"

#include "SDL3/SDL.h"

class SDL3Window;

class SDL3Renderer final : Renderer {
    protected:
        SDL_Renderer* renderer;
    
    public:
        SDL3Renderer(const SDL3Window& window, const char* driver = nullptr);
        ~SDL3Renderer() override;

        void setClearColor(const Color8 clearColor) override;
        void clear() override;
        void swapBuffers() override;
};