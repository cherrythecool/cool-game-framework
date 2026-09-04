#pragma once

#include "core/math/vector_2.hpp"
#include "core/math/vector_4.hpp"
#include "core/math/color.hpp"

class Renderer {
    protected:
        Renderer() {}
        
    public:
        virtual ~Renderer() = default;

        virtual void setClearColor(const Color8 clearColor) = 0;
        virtual void clear() = 0;
        virtual void swapBuffers() = 0;
        virtual void setLetterboxSize(Vector2i size) = 0;

		virtual void drawRect(const Vector4 rectangle, const Color8 color) = 0;
};
