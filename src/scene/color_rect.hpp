#pragma once

#include "scene/object_2d.hpp"

class ColorRect : public Object2D {
    public:
        Color8 color = {255, 255, 255, 255};
        Vector2 size = {0.0, 0.0};

        ColorRect(Vector2 size, Color8 color = {255, 255, 255, 255});
        virtual ~ColorRect();

        virtual void draw(void) override;
};