#include <iostream>

#include "SDL3/SDL.h"

struct Color8 {
    uint8_t r = 0;
    uint8_t g = 0;
    uint8_t b = 0;
    uint8_t a = 255;
};

struct Vector2i {
    int32_t x = 0;
    int32_t y = 0;
};

class Platform {
    protected:
        Platform() {}
        virtual ~Platform() = default;
    
    public:
        virtual void pollEvents() = 0;
        virtual bool requestedClose() = 0;
};

class SDL3Platform final : Platform {
    protected:
        bool hasRequestedClose = false;

    public:
        SDL3Platform() {
            if (!SDL_Init(SDL_INIT_VIDEO)) {
                std::cerr << "sdl init err: " << SDL_GetError() << std::endl;
                std::exit(1);
            }
        }

        ~SDL3Platform() override {
            SDL_Quit();
        }

        void pollEvents() override {
            SDL_Event event;
            while (SDL_PollEvent(&event)) {
                if (event.type == SDL_EVENT_QUIT) {
                    hasRequestedClose = true;
                }
            }
        }

        bool requestedClose() override {
            return hasRequestedClose;
        }
};

struct WindowFlags {
    bool resizable = true;
};

class Window {
    protected:
        Window(const char* title, const Vector2i size, const WindowFlags flags) {}
        virtual ~Window() = default;
    
    public:
        virtual void setTitle(const char* title) = 0;
        virtual void setSize(const Vector2i size) = 0;
        virtual void setFullscreen(const bool fullscreen) = 0;

        virtual std::string_view getTitle() const = 0;
        virtual Vector2i getSize() const = 0;
        virtual bool getFullscreen() const = 0;
};

class SDL3Renderer;

class SDL3Window final : Window {
    friend class SDL3Renderer;

    protected:
        SDL_Window* window = nullptr;

    public:
        SDL3Window(const char* title, const Vector2i size, const WindowFlags flags) : Window(title, size, flags) {
            SDL_WindowFlags sdlFlags = 0;

            if (flags.resizable) {
                sdlFlags |= SDL_WINDOW_RESIZABLE;
            }

            window = SDL_CreateWindow(title, size.x, size.y, sdlFlags);
            if (window == nullptr) {
                std::cerr << "sdl create window err: " << SDL_GetError() << std::endl;
                std::exit(1);
            }
        }

        ~SDL3Window() override {
            if (window != nullptr) {
                SDL_DestroyWindow(window);
            }
        }
    
        void setTitle(const char* title) {
            SDL_SetWindowTitle(window, title);
        }

        void setSize(const Vector2i size) {
            SDL_SetWindowSize(window, size.x, size.y);
        }

        void setFullscreen(const bool fullscreen) {
            SDL_SetWindowFullscreen(window, fullscreen);
        }

        std::string_view getTitle() const {
            return std::string_view(SDL_GetWindowTitle(window));
        }

        Vector2i getSize() const {
            Vector2i size;
            SDL_GetWindowSize(window, &size.x, &size.y);
            return size;
        }

        bool getFullscreen() const {
            return SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN;
        }
};

class Renderer {
    protected:
        Renderer() {}
        virtual ~Renderer() = default;
    
    public:
        virtual void setClearColor(const Color8 clearColor) = 0;
        virtual void clear() = 0;
        virtual void swapBuffers() = 0;
};

class SDL3Renderer final : Renderer {
    protected:
        SDL_Renderer* renderer;
    
    public:
        SDL3Renderer(const SDL3Window& window, const char* driver = nullptr) {
            renderer = SDL_CreateRenderer(window.window, driver);
            if (renderer == nullptr) {
                std::cerr << "sdl create renderer err: " << SDL_GetError() << std::endl;
                std::exit(1);
            }
        }

        ~SDL3Renderer() override {
            if (renderer != nullptr) {
                SDL_DestroyRenderer(renderer);
            }
        }

        void setClearColor(const Color8 clearColor) override {
            SDL_SetRenderDrawColor(renderer, clearColor.r, clearColor.g, clearColor.b, clearColor.a);
        }
    
        void clear() override {
            SDL_RenderClear(renderer);
        }
    
        void swapBuffers() override {
            SDL_RenderPresent(renderer);
        }
};

int main(void) {
    SDL3Platform platform = SDL3Platform();
    SDL3Window window = SDL3Window("i like audio", {800, 600}, {});
    SDL3Renderer renderer = SDL3Renderer(window);

    uint64_t start = SDL_GetTicksNS();
    uint64_t frames = 0;

    while (!platform.requestedClose()) {
        platform.pollEvents();

        frames++;
        if (SDL_GetTicksNS() - start >= 1000000000) {
            std::cout << frames << " FPS\n";
            frames = 0;
            start = SDL_GetTicksNS();
        }

        renderer.setClearColor({77, 77, 77});
        renderer.clear();
        renderer.swapBuffers();
    }

    return 0;
}