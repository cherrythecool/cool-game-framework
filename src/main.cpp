#include "core/application.hpp"

#include "scene/color_rect.hpp"
#include "scene/object.hpp"

#include <cmath>

class TestScene : public Object {
    protected:
        ColorRect* coolSquare;
        double time = 0.0;
        double counter = 0.0;

    public:
        TestScene() {
            coolSquare = new ColorRect({4, 4}, {255, 0, 0, 255});
            coolSquare->position = {0.0, 300.0 - 2.0};
            addChild(coolSquare);
        }

        ~TestScene() {

        }

        double mathFunc(void) {
            return tan(time * 2.0) * 16.0 + 4.0 - cos(time / 5.0) * 64.0;
        }

        void update(double deltaSeconds) override {
            counter += deltaSeconds;

            if (counter >= 1.0 / 120.0) {
                counter = 0.0;
                ColorRect* coolerSquare = new ColorRect(coolSquare->size, {sin(time) * 255, cos(time + 0.5) * 128, 0, 255});
                coolerSquare->position = coolSquare->position;
                addChild(coolerSquare);
            }

            coolSquare->position.x = time * 32.0;
            coolSquare->position.y = (300.0 - 2.0) + mathFunc();
            time += deltaSeconds;

            Object::update(deltaSeconds);
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
