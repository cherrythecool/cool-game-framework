#pragma once

#include <memory>
#include <string>

#include "core/assets/texture_loader.hpp"
#include "core/platform.hpp"
#include "core/window.hpp"
#include "core/renderer.hpp"
#include "core/math/color.hpp"
#include "core/math/vector_2.hpp"

#include "application_enums.hpp"
#include "scene/object.hpp"

struct ApplicationConfig {
    const char* name = nullptr;
    const ApplicationPlatform requestedPlatform = ApplicationPlatform::DEFAULT;
    const ApplicationRenderer requestedRenderer = ApplicationRenderer::DEFAULT;
    const bool resizable = true;
    const Vector2i size = {800, 600};
    const Color8 clearColor = {48, 48, 48, 255};
};

class Application {
    private:
        static Application* instance;

    protected:
        std::string_view name;
        Object* root = nullptr;

        std::shared_ptr<Platform> platform = nullptr;
        std::shared_ptr<Window> window = nullptr;
        std::shared_ptr<Renderer> renderer = nullptr;
        std::shared_ptr<TextureLoader> textureLoader = nullptr;

    public:
        Application(const ApplicationConfig config, Object* initialRoot = nullptr);
        ~Application();

        void run();

        std::shared_ptr<Renderer> getRenderer(void) const;
        std::shared_ptr<Window> getWindow(void) const;
        std::shared_ptr<Platform> getPlatform(void) const;
        std::shared_ptr<TextureLoader> getTextureLoader(void) const;

        void swapToRoot(Object* newRoot);
        Object* getRoot(void) const;

        static Application* getInstance(void);
};
