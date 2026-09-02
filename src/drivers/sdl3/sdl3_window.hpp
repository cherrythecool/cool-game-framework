#pragma once

#include "core/window.hpp"

#include <string>
#include "SDL3/SDL.h"

class SDL3Renderer;

class SDL3Window final : public Window {
    friend class SDL3Renderer;

    protected:
        SDL_Window* window = nullptr;

    public:
        SDL3Window(const char* title, const Vector2i size, const WindowFlags flags);
        ~SDL3Window() override;

        std::shared_ptr<Renderer> initRenderer(const ApplicationRenderer requestedRenderer) override;
    
        std::string_view getTitle() const override;
        Vector2i getSize() const override;
        bool getFullscreen() const override;

        void setTitle(const char* title) override;
        void setSize(const Vector2i size) override;
        void setFullscreen(const bool fullscreen) override;
};