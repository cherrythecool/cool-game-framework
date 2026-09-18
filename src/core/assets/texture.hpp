#pragma once

#include "core/math/vector_2.hpp"
#include <string_view>

class Texture {
    public:
        Texture() {}
        virtual ~Texture() = default;

        virtual void loadFromFile(std::string_view path) = 0;

        virtual Vector2i getSize() const = 0;
};
