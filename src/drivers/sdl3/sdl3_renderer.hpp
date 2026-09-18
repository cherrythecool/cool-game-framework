#pragma once

#include <string_view>

#include "SDL3/SDL.h"

#include "core/renderer.hpp"

class SDL3Renderer;

class SDL3Texture final : public Texture {
    friend SDL3Renderer;

    protected:
        SDL_Renderer* renderer = nullptr;
        SDL_Texture* texture = nullptr;

    public:
        SDL3Texture();
        ~SDL3Texture() override;

        void loadFromFile(std::string_view path) override;
        Vector2i getSize() const override;
};

class SDL3Window;

class SDL3Renderer final : public Renderer {
    friend SDL3Texture;

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
        void drawTexture(std::shared_ptr<Texture> texture, const Vector4 rectangle, const Color8 tint) override;

        std::shared_ptr<Texture> newTexture() override;
};
