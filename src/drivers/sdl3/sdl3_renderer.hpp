#pragma once

#include "core/renderer.hpp"

#include "SDL3/SDL.h"

class SDL3Window;

class SDL3Renderer final : public Renderer {
    protected:
        SDL_Renderer* renderer;
        Color8 clearColor;
        Vector2i letterboxSize = {0, 0};
    
    public:
        SDL3Renderer(const SDL3Window& window, const char* driver = nullptr);
        ~SDL3Renderer() override;

        void setClearColor(const Color8 clearColor) override;
        void clear() override;
        void swapBuffers() override;
        void setLetterboxSize(Vector2i size) override;

        void drawRect(const Vector4 rectangle, const Color8 color) override;
};
