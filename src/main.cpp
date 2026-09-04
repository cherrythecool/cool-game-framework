#include "core/application.hpp"

#include "scene/color_rect.hpp"
#include "scene/object.hpp"

class TestScene : public Object {
    protected:
        ColorRect* coolSquare;
        ColorRect* evilSquare;

    public:
        TestScene() {
            coolSquare = new ColorRect({64, 64}, {255, 100, 192, 255});
            coolSquare->position = {64.0, 64.0};
            addChild(coolSquare);

            evilSquare = new ColorRect({64, 64}, {255, 0, 64, 255});
            evilSquare->position = {800.0 - 64.0 - 64.0, 64.0};
            addChild(evilSquare);
        }

        ~TestScene() {

        }
};

int main(void) {
    Application app = Application(
        {
            "cool-game-framework - testing",
            ApplicationPlatform::SDL3,
            ApplicationRenderer::SDL3_RENDERER,
            true,
            {800, 600},
        },
        new TestScene()
    );
    
    app.run();
    return 0;
}
