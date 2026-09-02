#pragma once

#include "scene/object.hpp"

#include "core/math/vector_2.hpp"
#include "core/math/color.hpp"

class Object2D : public Object {
    public:
        Vector2 position = {0.0, 0.0};
        Vector2 scale = {1.0, 1.0};
        float64_t rotationDegrees = 0.0;
        Color tint = {1.0, 1.0, 1.0, 1.0};

        Object2D() = default;
        virtual ~Object2D() = default;
};