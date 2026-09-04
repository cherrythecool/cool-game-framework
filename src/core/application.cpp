#include "application.hpp"

#include "core/input_event.hpp"
#include "drivers/sdl3/sdl3_platform.hpp"
#include "drivers/sdl3/sdl3_renderer.hpp"
#include "drivers/sdl3/sdl3_window.hpp"
#include <iostream>

Application* Application::instance = nullptr;

Application::Application(const ApplicationConfig config, Object* initialRoot) {
    if (instance) {
        std::cerr << "error: cannot have more than one Application instance\n";
        std::exit(1);
    }

    instance = this;
    name = std::string_view(config.name);
    
    const WindowFlags windowFlags = WindowFlags {
        config.resizable,
    };

    switch (config.requestedPlatform) {
        case ApplicationPlatform::DEFAULT:
        case ApplicationPlatform::SDL3:
            platform = std::make_shared<SDL3Platform>();
            window = std::make_shared<SDL3Window>(config.name, config.size, windowFlags);
            break;
    }
    
    renderer = window->initRenderer(config.requestedRenderer);
    renderer->setClearColor(config.clearColor);
    renderer->setLetterboxSize(config.size);

    swapToRoot(initialRoot);
}

Application::~Application() {
    if (root) {
        delete root;
    }

    instance = nullptr;
}

void Application::run() {
    double lastTime = platform->getTimeSeconds();
    InputEvent inputEvent = InputEvent{};

    while (!platform->requestedClose()) {
        std::optional<InputEvent> platformEvent = platform->pollEvent();
        while (platformEvent.has_value()) {
            inputEvent = platformEvent.value();
            root->input(inputEvent);
            platformEvent = platform->pollEvent();
        }

        double deltaTime = platform->getTimeSeconds() - lastTime;
        lastTime = platform->getTimeSeconds();

        if (root) {
            root->update(deltaTime);
        }

        renderer->clear();

        if (root) {
            root->draw();
        }
        
        renderer->swapBuffers();
    }
}

std::shared_ptr<Renderer> Application::getRenderer(void) const {
    return renderer;
}

std::shared_ptr<Window> Application::getWindow(void) const {
    return window;
}

std::shared_ptr<Platform> Application::getPlatform(void) const {
    return platform;
}

void Application::swapToRoot(Object* newRoot) {
    Object* oldRoot = root;
    if (oldRoot == newRoot) {
        return;
    }

    root = newRoot;
    if (root) {
        root->added();
    }

    delete oldRoot;
}

Object* Application::getRoot(void) const {
    return root;
}

Application* Application::getInstance(void) {
    return instance;
}