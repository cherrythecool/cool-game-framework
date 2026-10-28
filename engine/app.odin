package engine

import "core:math"
import "base:runtime"
import "core:time"
import "core:fmt"
import "core:log"
import "core:mem"

import "core:math/linalg/glsl"
import "vendor:sdl3"
import gl "vendor:OpenGL"

AppInitConfig :: struct {
    title: cstring,
    content_size: glsl.ivec2,
    vsync: bool,
}

AppErrorType :: enum {
    BackendFailedToInitialize,
    AppAlreadyExists,
}

AppError :: struct {
    type: AppErrorType,
    message: cstring,
}

AppInitResult :: union {
    AppError, DisplayError, RendererError,
}

App: struct {
    // app state
    running: bool,
    ctx: runtime.Context,
    track: mem.Tracking_Allocator,

    // rendering / display
    main_display: Display,
    content_size: glsl.vec2,
    viewport: glsl.ivec4,
    window_size: glsl.ivec2,

    // game state
    current_scene: Scene,
    globals: [dynamic]GameObject,
} = {}

app_init :: proc(config: AppInitConfig) -> AppInitResult {
    if App.running {
        return AppError { .AppAlreadyExists, "" }
    }

    // https://gist.github.com/karl-zylinski/4ccf438337123e7c8994df3b03604e33
    when ODIN_DEBUG {
		mem.tracking_allocator_init(&App.track, context.allocator)
		context.allocator = mem.tracking_allocator(&App.track)
	}

    context.logger = log.create_console_logger()
    App.ctx = context

    App.running = true
    App.content_size = { f32(config.content_size.x), f32(config.content_size.y) }

    App.viewport = {0, 0, config.content_size.x, config.content_size.y}
    App.window_size = config.content_size

    if !sdl3.Init(sdl3.INIT_VIDEO | sdl3.INIT_AUDIO) {
        return AppError { .BackendFailedToInitialize, sdl3.GetError() }
    }

    device_result := sound_device_init()

    switch result in device_result {
        case cstring:
            fmt.panicf("failed to initialize audio device, error: %s", result)
    }

    display_result := app_make_display({ config.title, config.content_size.x, config.content_size.y, true })
    switch result in display_result {
        case Display:
            App.main_display = result
        case DisplayError:
            return result
        case RendererError:
            return result
    }

    gl.load_up_to(3, 3, sdl3.gl_set_proc_address)

    if config.vsync {
        if !display_set_vsync(&App.main_display, .Adaptive) {
            display_set_vsync(&App.main_display, .Enabled)
        }
    } else {
        if !display_set_vsync(&App.main_display, .Disabled) {
            log.warnf("Failed to disable VSync with SDL3, reason: %s", sdl3.GetError())
        }
    }

    bind_result := renderer_bind(&App.main_display)
    if bind_result != nil {
        return bind_result.(RendererError)
    }

    renderer := &App.main_display.renderer
    renderer.default_quad = renderer_make_quad(&App.main_display)
    renderer.projection_matrix = glsl.mat4Ortho3d(0, App.content_size.x, App.content_size.y, 0, -1, 1)

    assets_init()

    return nil
}

app_deinit :: proc() {
    scene_deinit(&App.current_scene)
    assets_deinit()
    display_deinit(&App.main_display)
    sound_device_deinit()
    sdl3.Quit()

    log.destroy_console_logger(App.ctx.logger)

    when ODIN_DEBUG {
        if len(App.track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations leaked: ===\n", len(App.track.allocation_map))
            for _, entry in App.track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }

        if len(App.track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(App.track.bad_free_array))
            for entry in App.track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }

        mem.tracking_allocator_destroy(&App.track)
    }

    App = {}
}

app_run :: proc() {
    timer: f32 = 0.0

    last_ticks := sdl3.GetTicksNS()
    frames := 0

    previous_frame := sdl3.GetTicksNS()
    current_frame := sdl3.GetTicksNS()
    delta_seconds: f64 = 0

    for App.running {
        current_frame = sdl3.GetTicksNS()
        delta_seconds = f64(current_frame - previous_frame) / f64(time.Second / time.Nanosecond)

        app_poll()
        app_update(delta_seconds)
        app_draw()

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

app_poll :: proc() {
    event: sdl3.Event

    for sdl3.PollEvent(&event) {
        #partial switch event.type {
            case .KEY_DOWN:
                key := event.key.key
            case .WINDOW_RESIZED:
                w := event.window.data1
                h := event.window.data2

                App.window_size = {w, h}

                if (f32(w) / f32(h) > f32(App.content_size.x) / f32(App.content_size.y)) {
                    w = auto_cast math.round(f32(App.content_size.x) * (f32(h) / f32(App.content_size.y)))
                } else {
                    h = auto_cast math.round(f32(App.content_size.y) * (f32(w) / f32(App.content_size.x)))
                }

                App.viewport.z = w
                App.viewport.w = h

                App.viewport.x = (App.window_size.x - App.viewport.z) / 2
                App.viewport.y = (App.window_size.y - App.viewport.w) / 2
            case .QUIT:
                App.running = false
        }
    }
}

app_update :: proc(delta_seconds: f64) {
    scene_update(&App.current_scene, delta_seconds)
}

app_draw :: proc() {
    app_clear_screen()

    scene_draw(&App.current_scene, &App.main_display.renderer)

    swap_error := display_swap_buffers(&App.main_display)
    if swap_error.type != .None {
        if swap_error.message != nil {
            fmt.panicf("Failed to swap window buffers, error: %v, error message: %s", swap_error.type, swap_error.message)
        } else {
            fmt.panicf("Failed to swap window buffers, error: %v", swap_error.type)
        }
    }
}

app_clear_screen :: proc() {
    gl.Viewport(0, 0, App.window_size.x, App.window_size.y)

    renderer_clear_color_buffer(&App.main_display.renderer, glsl.vec4 { 0.0, 0.0, 0.0, 1.0 })

    {
        gl.Enable(gl.SCISSOR_TEST)
        defer gl.Disable(gl.SCISSOR_TEST)

        gl.Viewport(App.viewport.x, App.viewport.y, App.viewport.z, App.viewport.w)
        gl.Scissor(App.viewport.x, App.viewport.y, App.viewport.z, App.viewport.w)
        renderer_clear_color_buffer(&App.main_display.renderer, glsl.vec4 { 0.6, 0.6, 0.6, 1.0 })
    }
}

app_make_display :: proc(config: DisplayInitConfig) -> union { Display, DisplayError, RendererError } {
    display_result := display_init(config)
    switch result in display_result {
        case Display:
            return result
        case DisplayError:
            return result
        case RendererError:
            return result
        case:
            return nil
    }
}