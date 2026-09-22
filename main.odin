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

    main_loop: for {
        event: sdl3.Event
        for sdl3.PollEvent(&event) {
            #partial switch event.type {
                case .KEY_DOWN:
                    key := event.key.key
                    if key == sdl3.K_SPACE {
                        sound.stream_set_paused(&song, !sound.stream_is_paused(&song))
                    }

                case .WINDOW_RESIZED:
                    w := event.window.data1
                    h := event.window.data2

                    app.window_size = {w, h}

                    if (f32(w) / f32(h) > f32(app.content_size.x) / f32(app.content_size.y)) {
                        w = i32(f32(app.content_size.x) * (f32(h) / f32(app.content_size.y)))
                    } else {
                        h = i32(f32(app.content_size.y) * (f32(w) / f32(app.content_size.x)))
                    }

                    app.viewport.z = w
                    app.viewport.w = h

                    app.viewport.x = (app.window_size.x - app.viewport.z) / 2
                    app.viewport.y = (app.window_size.y - app.viewport.w) / 2
                case .QUIT:
                    break main_loop
                case .WINDOW_FOCUS_GAINED:
                    last_focused = event.window.windowID
                }
        }

        if sdl3.GetTicksNS() - last_ticks >= 1_000_000 * 1000 {
            fmt.printfln("%v FPS", frames)
            frames = 0
            last_ticks = sdl3.GetTicksNS()
        }

        frames += 1
        timer = f32(f64(sdl3.GetTicksNS()) / 1_000_000.0) / 1000.0

        gl.Viewport(0, 0, app.window_size.x, app.window_size.y)

        rendering.renderer_set_clear_color(&app.main_display.renderer, { 0.0, 0.0, 0.0, 1.0 })
        rendering.renderer_clear_color_buffer(&app.main_display.renderer, nil)

        {
            gl.Enable(gl.SCISSOR_TEST)
            defer gl.Disable(gl.SCISSOR_TEST)
    
            gl.Viewport(app.viewport.x, app.viewport.y, app.viewport.z, app.viewport.w)
            gl.Scissor(app.viewport.x, app.viewport.y, app.viewport.z, app.viewport.w)
            rendering.renderer_set_clear_color(&app.main_display.renderer, { 0.08, 0.08, 0.08, 1.0 })
            rendering.renderer_clear_color_buffer(&app.main_display.renderer, nil)
        }

        rendering.shader_bind(shader_program)
        screen_transform = glsl.mat4Ortho3d(0, f32(app.content_size.x), f32(app.content_size.y), 0, -1, 1)
        rendering.shader_set_uniform(&shader_program, "projectionMatrix", screen_transform)

        scale_x: f32 = math.sin(timer) * 0.5 + 1.5
        scale_y: f32 = math.sin(timer*3.14) * 0.7 + 1.7
        size := glsl.vec3{f32(dog.width)*scale_x, f32(dog.height)*scale_y, 1.0}

        transform = 1
        transform *= glsl.mat4Translate(glsl.vec3{
            math.wrap(timer * 256.0, 1280+(size.x/2.0)),
            math.tan(timer*2.0) * 50.0 + 60.0,
            0.0,
        })
        transform *= glsl.mat4Translate(glsl.vec3{
            -size.x / 2.0,
            -size.y / 2.0,
            0.0,
        })
        transform *= glsl.mat4Scale(size)
        transform *= glsl.mat4Scale(glsl.vec3{0.5, 0.5, 1.0})

        rendering.shader_set_uniform(&shader_program, "modelMatrix", transform)

        rendering.texture_bind(dog)
        rendering.mesh_draw_triangles(app.default_quad)

        swap_error := rendering.display_swap_buffers(&app.main_display)
        if swap_error.type != .None {
            if swap_error.message != nil {
                fmt.panicf("Failed to swap window buffers, error: %v, error message: %s", swap_error.type, swap_error.message)
            } else {
                fmt.panicf("Failed to swap window buffers, error: %v", swap_error.type)
            }
        }
    }
}