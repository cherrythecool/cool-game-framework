#pragma once

#include "core/asset_loader.hpp"
#include "core/renderer.hpp"
#include "core/assets/texture.hpp"
#include <memory>

class TextureLoader : public AssetLoader<Texture> {
    protected:
        std::shared_ptr<Renderer> renderer = nullptr;

    public:
        TextureLoader(std::shared_ptr<Renderer> renderer);
        ~TextureLoader() override;

        std::shared_ptr<Texture> get(std::string_view path) override;
};
