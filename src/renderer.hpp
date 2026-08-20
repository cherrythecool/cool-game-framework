#pragma once

#include "color.hpp"

class Renderer {
    protected:
        Renderer() {}
        virtual ~Renderer() = default;
    
    public:
        virtual void setClearColor(const Color8 clearColor) = 0;
        virtual void clear() = 0;
        virtual void swapBuffers() = 0;
};