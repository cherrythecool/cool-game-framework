#include "application.hpp"

#include "drivers/sdl3/sdl3_platform.hpp"

Application::Application(const ApplicationConfig config) {
    name = std::string_view(config.name);
    
    switch (config.requestedPlatform) {
        case ApplicationPlatform::DEFAULT:
        case ApplicationPlatform::SDL3:
            platform = std::make_unique<SDL3Platform>();
            break;
    }
}

Application::~Application() {}