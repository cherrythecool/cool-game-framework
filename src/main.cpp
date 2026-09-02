#include "core/application.hpp"

int main(void) {
    Application app = Application({
        "cool-game-framework - testing",
        ApplicationPlatform::SDL3,
        ApplicationRenderer::SDL3_RENDERER,
        true,
        {800, 600},
    });

    app.run();
    return 0;
}
