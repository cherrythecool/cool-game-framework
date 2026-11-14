package main

import "base:runtime"
import "core:fmt"
import lua "vendor:lua/5.4"

import "engine"

main :: proc() {
    app_result := engine.app_init({
        title = "cosmo(s)",
        script_file_path = "game/test_scene.lua",
        content_size = { 1280, 720 },
        vsync = true,
    })
    context = engine.App.ctx
    defer engine.app_deinit()

    switch result in app_result {
        case engine.AppError:
            fmt.panicf("Failed to initialize app, error: %v", result)
        case engine.DisplayError:
            fmt.panicf("Failed to initialize app display, error: %v", result)
        case engine.RendererError:
            fmt.panicf("Failed to initialize app renderer, error: %v", result)
    }

    engine.app_run()
}