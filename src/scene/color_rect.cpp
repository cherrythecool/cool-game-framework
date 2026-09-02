#include "color_rect.hpp"

#include "core/application.hpp"

ColorRect::ColorRect(Vector2 size, Color8 color) {
    this->size = size;
    this->color = color;
}

ColorRect::~ColorRect() {}

void ColorRect::draw(void) {
    Application::getInstance()->getRenderer()->drawRect(
        {position.x, position.y, size.x * scale.x, size.y * scale.y},
        {
            (uint8_t)(MIN(color.r * MAX(tint.r, 0.0), 255)),
            (uint8_t)(MIN(color.g * MAX(tint.g, 0.0), 255)),
            (uint8_t)(MIN(color.b * MAX(tint.b, 0.0), 255)),
            (uint8_t)(MIN(color.a * MAX(tint.a, 0.0), 255)),
        }
    );

    Object2D::draw();
}