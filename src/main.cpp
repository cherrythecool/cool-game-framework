#include "core/application.hpp"

#include "scene/color_rect.hpp"
#include "scene/object.hpp"
#include "scene/sprite_2d.hpp"

#include <cmath>

class TestScene : public Object {
    protected:
        ColorRect* coolSquare;
        ColorRect* evilSquare;
        Sprite2D* kindBunny;

    public:
        TestScene() {}

        ~TestScene() {}

        void added() override {
            coolSquare = new ColorRect({64, 64}, {255, 100, 192, 255});
            coolSquare->position = {64.0, 64.0};
            addChild(coolSquare);

            evilSquare = new ColorRect({64, 64}, {255, 0, 64, 255});
            evilSquare->position = {800.0 - 64.0 - 64.0, 64.0};
            addChild(evilSquare);

            kindBunny = new Sprite2D(Application::getInstance()->getTextureLoader()->get("assets/test_bunny.png"));
            kindBunny->position = {400, 300};
            addChild(kindBunny);
        }

        void update(double deltaSeconds) override {
            double time = Application::getInstance()->getPlatform()->getTimeSeconds();
            time *= 3.0;
            kindBunny->scale = {sin(time) * 0.5 + 1.0, sin(time) * 0.5 + 1.0};
        }
};

int main(void) {
    Application app = Application(
        {
            "cool math",
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
