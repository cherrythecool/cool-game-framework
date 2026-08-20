#pragma once

#include <memory>
#include <string>

#include "core/platform.hpp"
#include "core/window.hpp"
#include "core/renderer.hpp"

enum class ApplicationPlatform {
    DEFAULT = 0,
    SDL3,
};

enum class ApplicationRenderer {
    DEFAULT = 0,
    SDL3_RENDERER,
};

struct ApplicationConfig {
    const char* name = nullptr;
    const ApplicationPlatform requestedPlatform = ApplicationPlatform::DEFAULT;
    const ApplicationRenderer requestedRenderer = ApplicationRenderer::DEFAULT;
};

class Application {
    protected:
        std::unique_ptr<Platform> platform;
        std::unique_ptr<Window> window;
        std::unique_ptr<Renderer> renderer;

        std::string_view name;

    public:
        Application(const ApplicationConfig config);
        ~Application();
};