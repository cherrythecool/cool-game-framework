package rendering

import "core:c"

import "core:math/linalg/glsl"
import "vendor:sdl3"

Display :: struct {
    source: ^sdl3.Window,
    source_id: sdl3.WindowID,
    renderer: Renderer,
}

DisplayErrorType :: enum {
    None = 0,
    BackendFailedToCreate,
    BackendFailedToSwapBuffers,
}

DisplayError :: struct {
    type: DisplayErrorType,
    message: cstring,
}

DisplayVSyncMode :: enum {
    Disabled = 0,
    Enabled = 1,
    Adaptive = -1,
}

DisplayInitConfig :: struct {
    title: cstring,
    width: i32,
    height: i32,
    resizable: bool,
}

DisplayInitResult :: union {
    Display, DisplayError, RendererError,
}

display_init :: proc(config: DisplayInitConfig) -> DisplayInitResult {
    sdl3.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
    sdl3.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3)
    
    when ODIN_OS == .Darwin {
        // Thank you macOS. Very cool.
        sdl3.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl3.GLProfile.COMPATIBILITY))
        sdl3.GL_SetAttribute(.CONTEXT_FLAGS, i32(sdl3.GLContextFlag.FORWARD_COMPATIBLE))
    } else {
        sdl3.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl3.GLProfile.CORE))
    }
    
    flags := sdl3.WindowFlags { .OPENGL }
    if config.resizable {
        flags |= sdl3.WindowFlags { .RESIZABLE }
    }
    
    display: Display
    display.source = sdl3.CreateWindow(
        config.title,
        config.width,
        config.height,
        flags,
    )

    if display.source == nil {
        return DisplayError { .BackendFailedToCreate, sdl3.GetError() }
    }

    display.source_id = sdl3.GetWindowID(display.source)

    renderer_result := renderer_init(&display)
    switch result in renderer_result {
        case Renderer:
            display.renderer = result
        case RendererError:
            return result
    }

    return display
}

display_deinit :: proc(display: ^Display) {
    renderer_deinit(display)
    sdl3.DestroyWindow(display.source)
}

display_swap_buffers :: proc(display: ^Display) -> DisplayError {
    if !sdl3.GL_SwapWindow(display.source) {
        return DisplayError { .BackendFailedToSwapBuffers, sdl3.GetError() }
    }

    return { .None, nil }
}

display_set_vsync :: proc(display: ^Display, vsync_mode: DisplayVSyncMode) -> bool {
    renderer_bind(display)
    return sdl3.GL_SetSwapInterval(i32(vsync_mode))
}

display_get_size :: proc(display: ^Display) -> glsl.ivec2 {
    width, height: c.int
    if !sdl3.GetWindowSize(display.source, &width, &height) {
        return { 0, 0 }
    }

    return { width, height }
}

display_focus :: proc(display: ^Display) -> bool {
    return sdl3.RaiseWindow(display.source)
}