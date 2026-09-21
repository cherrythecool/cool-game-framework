package engine

import "core:slice"
import "core:fmt"
import "core:log"

import "core:math/linalg/glsl"
import "vendor:sdl3"
import gl "vendor:OpenGL"

import "../rendering"

App :: struct {
    main_display: rendering.Display,
    content_size: glsl.vec2,
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
        }
    }

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

    return app
}

app_deinit :: proc(app: ^App) {
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