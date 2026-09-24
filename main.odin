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

    dog: rendering.Texture
    dog_result := rendering.texture_load("assets/dog.png")
    switch result in dog_result {
        case rendering.Texture:
            dog = result
        case rendering.TextureLoadError:
            fmt.panicf("Failed to load texture with error: %v", result)
    }

    defer rendering.texture_deinit(dog)

    shader_program: rendering.ShaderProgram
    shader_result := rendering.shader_load("assets/shaders/sprite.frag", "assets/shaders/sprite.vert")
    switch result in shader_result {
        case rendering.ShaderProgram:
            shader_program = result
        case rendering.ShaderCompileError:
            fmt.panicf("Failed to compile shader, error: %v", result)
        case rendering.ShaderLoadError:
            fmt.panicf("Failed to load shader, error: %v", result)
        case os.Error:
            fmt.panicf("Failed to read file from os, error: %v", result)
    }
    defer rendering.shader_free(&shader_program)
    rendering.shader_bind(shader_program)

    gl.ActiveTexture(gl.TEXTURE0)
    rendering.texture_bind(dog)

    transform: glsl.mat4 = 1
    transform *= glsl.mat4Scale(glsl.vec3{f32(dog.width), f32(dog.height), 1.0})
    rendering.shader_set_uniform(&shader_program, "modelMatrix", transform)

    screen_transform: glsl.mat4 = glsl.mat4Ortho3d(0, 1280, 720, 0, -1, 1)
    rendering.shader_set_uniform(&shader_program, "projectionMatrix", screen_transform)

    timer: f32 = 0.0

    last_ticks := sdl3.GetTicksNS()
    frames := 0

    last_focused: sdl3.WindowID

    DOG_SPRITE := game.sprite_init(dog)

    engine.app_run(&app)
}