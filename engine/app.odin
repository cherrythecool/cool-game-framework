package engine

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
    // rendering / display
    main_display: rendering.Display,
    content_size: glsl.vec2,
    viewport: glsl.ivec4,
    window_size: glsl.ivec2,
    default_quad: rendering.Mesh,

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
        content_size = {
            f32(config.content_size.x),
            f32(config.content_size.y),
        },
    }

    app.viewport = {0, 0, config.content_size.x, config.content_size.y}
    app.window_size = config.content_size

    if !sdl3.Init(sdl3.INIT_VIDEO | sdl3.INIT_AUDIO) {
        return AppError { .BackendFailedToInitialize, sdl3.GetError() }
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

    app.default_quad = app_init_quad(&app)

    return app
}

app_deinit :: proc(app: ^App) {
    rendering.mesh_deinit(&app.default_quad)
    rendering.display_deinit(&app.main_display)
    sdl3.Quit()
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

app_init_quad :: proc(app: ^App) -> rendering.Mesh {
    rendering.renderer_bind(&app.main_display)

    // tightly packed as vec2 for vertex positions & vec2 for uvs
    quad_vertices: []f32 = {
        0.0, 1.0,  0.0, 1.0,   // top left
        0.0, 0.0,  0.0, 0.0,   // bottom left
        1.0, 0.0,  1.0, 0.0,   // bottom right
        1.0, 1.0,  1.0, 1.0,   // top right
    }

    quad_indices: []u32 = {
        0, 1, 3,
        1, 2, 3,
    }

    return rendering.mesh_init(quad_vertices, quad_indices, {
        {
            count = 2,
            type = .F32,
            normalize = false,
            bytes_between_each = 4 * size_of(f32),
            bytes_from_each = 0,
        },
        {
            count = 2,
            type = .F32,
            normalize = false,
            bytes_between_each = 4 * size_of(f32),
            bytes_from_each = 2 * size_of(f32),
        },
    })
}