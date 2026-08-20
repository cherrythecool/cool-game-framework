#pragma once

#include "math/color.hpp"

class Renderer {
    protected:
        Renderer() {}
        
    public:
        virtual ~Renderer() = default;

        virtual void setClearColor(const Color8 clearColor) = 0;
        virtual void clear() = 0;
        virtual void swapBuffers() = 0;


};