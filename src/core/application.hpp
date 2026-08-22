#pragma once

#include <memory>
#include <string>

#include "core/platform.hpp"
#include "core/window.hpp"
#include "core/renderer.hpp"
#include "math/color.hpp"
#include "math/vector_2.hpp"

#include "application_enums.hpp"

struct ApplicationConfig {
    const char* name = nullptr;
    const ApplicationPlatform requestedPlatform = ApplicationPlatform::DEFAULT;
    const ApplicationRenderer requestedRenderer = ApplicationRenderer::DEFAULT;
    const Vector2i size = {800, 600};
    const Color8 clearColor = {48, 48, 48, 255};
};

class Application {
    protected:
        std::unique_ptr<Platform> platform = nullptr;
        std::unique_ptr<Window> window = nullptr;
        std::unique_ptr<Renderer> renderer = nullptr;

        std::string_view name;

    public:
        Application(const ApplicationConfig config);
        ~Application();

        void run();
};