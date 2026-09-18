#include "sprite_2d.hpp"
#include "core/application.hpp"
#include "scene/object_2d.hpp"

Sprite2D::Sprite2D(std::shared_ptr<Texture> texture) : texture(texture) {}
Sprite2D::~Sprite2D() {}

void Sprite2D::draw() {
    if (texture) {
        Vector2i textureSizeI = texture->getSize();
        Vector2 textureSize = {static_cast<float64_t>(textureSizeI.x), static_cast<float64_t>(textureSizeI.y)};
        Vector4 destRectangle = {position.x, position.y, textureSize.x * scale.x, textureSize.y * scale.y};
        destRectangle.x -= destRectangle.z * originRatio.x;
        destRectangle.y -= destRectangle.w * originRatio.y;

        Application::getInstance()->getRenderer()->drawTexture(texture, destRectangle, {
            (uint8_t)(MIN(tint.r, 255)),
            (uint8_t)(MIN(tint.g, 255)),
            (uint8_t)(MIN(tint.b, 255)),
            (uint8_t)(MIN(tint.a, 255)),
        });
    }

    Object2D::draw();
}

std::shared_ptr<Texture> Sprite2D::getTexture() const {
    return texture;
}