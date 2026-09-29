package main

import "core:time"
import "base:runtime"

import "core:c"
import "core:os"
import "core:log"
import "core:math"
import "core:fmt"

import "vendor:sdl3"
import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

import "engine"
import "sound"
import "rendering"
import "game"

main :: proc() {
    context.logger = log.create_console_logger()

    app: engine.App
    app_result := engine.app_init({
        title = "cgf version idek",
        content_size = { 1280, 720 },
        vsync = true,
    })
    defer engine.app_deinit(&app)

    switch result in app_result {
        case engine.App:
            app = result
        case engine.AppError:
            fmt.panicf("Failed to initialize app, error: %v", result)
        case rendering.DisplayError:
            fmt.panicf("Failed to initialize app display, error: %v", result)
        case rendering.RendererError:
            fmt.panicf("Failed to initialize app renderer, error: %v", result)
    }

    song: sound.CherryStream
    song_result := sound.stream_init(&app.sound_device, "assets/TestSong.ogg")
    defer sound.stream_deinit(&song)
    
    switch result in song_result {
        case sound.CherryStream:
            song = result
        case cstring:
            log.warnf("Failed to load song, error: %s", result)
    }

    sound.device_resume_playback(&app.sound_device)

    DOG_SPRITE := game.sprite_init("assets/dog.png")
    append(&app.current_scene.objects, DOG_SPRITE)

    engine.app_run(&app)
}