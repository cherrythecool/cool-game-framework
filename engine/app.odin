package engine

import "core:time"
import "core:slice"
import "core:fmt"
import "core:log"

import "core:math/linalg/glsl"
import "vendor:sdl3"
import gl "vendor:OpenGL"

import "../rendering"
import "../sound"
import "../game"

App :: struct {
    // app state
    running: bool,

    // rendering / display
    main_display: rendering.Display,
    content_size: glsl.vec2,
    viewport: glsl.ivec4,
    window_size: glsl.ivec2,

    // sound
    sound_device: sound.Device,

    // game state
    current_scene: game.Scene,
    globals: [dynamic]game.GameObject,
}

AppInitConfig :: struct {
    title: cstring,
    content_size: glsl.ivec2,
    vsync: bool,
}

AppErrorType :: enum {
    BackendFailedToInitialize,
}

AppError :: struct {
    type: AppErrorType,
    message: cstring,
}

AppInitResult :: union {
    App, AppError, rendering.DisplayError, rendering.RendererError,
}

app_init :: proc(config: AppInitConfig) -> AppInitResult {
    app: App = {
        running = true,
        content_size = { f32(config.content_size.x), f32(config.content_size.y) },
    }

    app.viewport = {0, 0, config.content_size.x, config.content_size.y}
    app.window_size = config.content_size

    if !sdl3.Init(sdl3.INIT_VIDEO | sdl3.INIT_AUDIO) {
        return AppError { .BackendFailedToInitialize, sdl3.GetError() }
    }

    device_result := sound.device_init()

    switch result in device_result {
        case sound.Device:
            app.sound_device = result
        case cstring:
            fmt.panicf("failed to initialize audio device, error: %s", result)
    }

    display_result := app_make_display(&app, { config.title, config.content_size.x, config.content_size.y, true })
    switch result in display_result {
        case rendering.Display:
            app.main_display = result
        case rendering.DisplayError:
            return result
        case rendering.RendererError:
            return result
    }

    gl.load_up_to(3, 3, sdl3.gl_set_proc_address)

    if config.vsync {
        if !rendering.display_set_vsync(&app.main_display, .Adaptive) {
            rendering.display_set_vsync(&app.main_display, .Enabled)
        }
    } else {
        if !rendering.display_set_vsync(&app.main_display, .Disabled) {
            log.warnf("Failed to disable VSync with SDL3, reason: %s", sdl3.GetError())
        }
    }

    bind_result := rendering.renderer_bind(&app.main_display)
    if bind_result != nil {
        return bind_result.(rendering.RendererError)
    }

    renderer := &app.main_display.renderer
    renderer.default_quad = rendering.renderer_make_quad(&app.main_display)
    renderer.projection_matrix = glsl.mat4Ortho3d(0, app.content_size.x, app.content_size.y, 0, -1, 1)

    return app
}

app_deinit :: proc(app: ^App) {
    game.scene_deinit(&app.current_scene)

    rendering.display_deinit(&app.main_display)
    sound.device_deinit(&app.sound_device)
    sdl3.Quit()
}

app_run :: proc(app: ^App) {
    timer: f32 = 0.0

    last_ticks := sdl3.GetTicksNS()
    frames := 0

    previous_frame := sdl3.GetTicksNS()
    current_frame := sdl3.GetTicksNS()
    delta_seconds: f64 = 0

    for app.running {
        current_frame = sdl3.GetTicksNS()
        delta_seconds = f64(current_frame - previous_frame) / f64(time.Second / time.Nanosecond)

        app_poll(app)
        app_update(app, delta_seconds)
        app_draw(app)

        if sdl3.GetTicksNS() - last_ticks >= 1_000_000 * 1000 {
            fmt.printfln("%v FPS", frames)
            frames = 0
            last_ticks = sdl3.GetTicksNS()
        }

        frames += 1
        timer = f32(f64(sdl3.GetTicksNS()) / 1_000_000.0) / 1000.0

        previous_frame = current_frame
    }
}

app_poll :: proc(app: ^App) {
    event: sdl3.Event
    for sdl3.PollEvent(&event) {
        #partial switch event.type {
            case .KEY_DOWN:
                key := event.key.key
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
                app.running = false
        }
    }
}

app_update :: proc(app: ^App, delta_seconds: f64) {
    game.scene_update(&app.current_scene, delta_seconds)
}

app_draw :: proc(app: ^App) {
    app_clear_screen(app)

    game.scene_draw(&app.current_scene, &app.main_display.renderer)

    swap_error := rendering.display_swap_buffers(&app.main_display)
    if swap_error.type != .None {
        if swap_error.message != nil {
            fmt.panicf("Failed to swap window buffers, error: %v, error message: %s", swap_error.type, swap_error.message)
        } else {
            fmt.panicf("Failed to swap window buffers, error: %v", swap_error.type)
        }
    }
}

app_clear_screen :: proc(app: ^App) {
    gl.Viewport(0, 0, app.window_size.x, app.window_size.y)

    rendering.renderer_clear_color_buffer(&app.main_display.renderer, glsl.vec4 { 0.0, 0.0, 0.0, 1.0 })

    {
        gl.Enable(gl.SCISSOR_TEST)
        defer gl.Disable(gl.SCISSOR_TEST)

        gl.Viewport(app.viewport.x, app.viewport.y, app.viewport.z, app.viewport.w)
        gl.Scissor(app.viewport.x, app.viewport.y, app.viewport.z, app.viewport.w)
        rendering.renderer_clear_color_buffer(&app.main_display.renderer, glsl.vec4 { 0.6, 0.6, 0.6, 1.0 })
    }
}

app_make_display :: proc(app: ^App, config: rendering.DisplayInitConfig) -> union { rendering.Display, rendering.DisplayError, rendering.RendererError } {
    display_result := rendering.display_init(config)
    switch result in display_result {
        case rendering.Display:
            return result
        case rendering.DisplayError:
            return result
        case rendering.RendererError:
            return result
        case:
            return nil
    }
}