#include "core/assets/texture_loader.hpp"
#include "core/application.hpp"

TextureLoader::TextureLoader(std::shared_ptr<Renderer> renderer) {
    this->renderer = renderer;
}

TextureLoader::~TextureLoader() {}

std::shared_ptr<Texture> TextureLoader::get(std::string_view path) {
    if (assets.count(path) > 0 && !assets[path].expired()) {
        return assets[path].lock();
    } else {
        std::shared_ptr<Texture> texture = renderer->newTexture();
        texture->loadFromFile(path);
        assets[path] = texture;
        return texture;
    }
}
