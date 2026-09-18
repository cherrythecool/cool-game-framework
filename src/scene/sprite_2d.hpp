#pragma once

#include "core/math/vector_2.hpp"
#include "scene/object_2d.hpp"

#include "core/assets/texture.hpp"

class Sprite2D : public Object2D {
    protected:
        std::shared_ptr<Texture> texture = nullptr;

    public:
        Vector2 originRatio = {0.5 ,0.5};

        Sprite2D(std::shared_ptr<Texture> texture);
        virtual ~Sprite2D();

        virtual void draw() override;

        std::shared_ptr<Texture> getTexture() const;
};
