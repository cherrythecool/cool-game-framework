#pragma once

#include <memory>
#include <string_view>
#include <unordered_map>

template<typename T>
class AssetLoader {
    protected:
        AssetLoader<T>() {}

        std::unordered_map<std::string_view, std::weak_ptr<T>> assets;
    
    public:
        virtual ~AssetLoader<T>() = default;

        virtual std::shared_ptr<T> loadAsset(std::string_view path) = 0;
};