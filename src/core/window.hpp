#pragma once

#include <string>
#include "math/vector_2.hpp"

struct WindowFlags {
    bool resizable = true;
};

class Window {
    protected:
        Window(const char* title, const Vector2i size, const WindowFlags flags) {}
        
    public:
        virtual ~Window() = default;

        virtual std::string_view getTitle() const = 0;
        virtual Vector2i getSize() const = 0;
        virtual bool getFullscreen() const = 0;

        virtual void setTitle(const char* title) = 0;
        virtual void setSize(const Vector2i size) = 0;
        virtual void setFullscreen(const bool fullscreen) = 0;
};