#include <iostream>

#include "core/application.hpp"

int main(void) {
    Application app = Application({
        "test",
        ApplicationPlatform::SDL3,
        ApplicationRenderer::SDL3_RENDERER,
        true,
        {640, 480},
    });

    app.run();
    return 0;
}