#include <iostream>

#include "core/application.hpp"

int main(void) {
    Application app = Application({
        "test",
        ApplicationPlatform::SDL3,
    });

    // SDL3Platform platform = SDL3Platform();
    // SDL3Window window = SDL3Window("cool game!", {800, 600}, {});
    // SDL3Renderer renderer = SDL3Renderer(window);

    // float64_t start = platform.getTimeSeconds();
    // uint64_t frames = 0;

    // while (!platform.requestedClose()) {
    //     platform.pollEvents();

    //     frames++;
    //     if (platform.getTimeSeconds() - start >= 1.0) {
    //         std::cout << frames << " FPS\n";
    //         frames = 0;
    //         start = platform.getTimeSeconds();
    //     }

    //     renderer.setClearColor({77, 77, 77});
    //     renderer.clear();
    //     renderer.swapBuffers();
    // }

    return 0;
}