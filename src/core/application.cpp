#include "application.hpp"

#include "drivers/sdl3/sdl3_platform.hpp"
#include "drivers/sdl3/sdl3_renderer.hpp"
#include "drivers/sdl3/sdl3_window.hpp"

Application::Application(const ApplicationConfig config) {
    name = std::string_view(config.name);
    
    switch (config.requestedPlatform) {
        case ApplicationPlatform::DEFAULT:
        case ApplicationPlatform::SDL3:
            platform = std::make_unique<SDL3Platform>();
            window = std::make_unique<SDL3Window>(config.name, config.size, WindowFlags {});
            break;
    }
    
    renderer = window->initRenderer(config.requestedRenderer);
    renderer->setClearColor(config.clearColor);
}

Application::~Application() {}

void Application::run() {
    while (!platform->requestedClose()) {
        platform->pollEvents();

        renderer->clear();
        renderer->swapBuffers();
    }
}