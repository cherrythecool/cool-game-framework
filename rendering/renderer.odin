package rendering

import "core:math/linalg/glsl"
import "vendor:sdl3"
import gl "vendor:OpenGL"

Renderer :: struct {
    ctx: sdl3.GLContext,
}

RendererErrorType :: enum {
    BackendFailedToCreateRenderingContext,
    BackendFailedToBindRenderingContext,
}

RendererError :: struct {
    type: RendererErrorType,
    message: cstring,
}

RendererInitResult :: union {
    Renderer, RendererError,
}

renderer_init :: proc(display: ^Display) -> RendererInitResult {
    renderer: Renderer
    renderer.ctx = sdl3.GL_CreateContext(display.source)
    
    if renderer.ctx == nil {
        return RendererError { .BackendFailedToCreateRenderingContext, sdl3.GetError() }
    }

    return renderer
}

renderer_deinit :: proc(renderer: ^Renderer) {
    sdl3.GL_DestroyContext(renderer.ctx)
}

renderer_bind :: proc(parent: ^Display) -> Maybe(RendererError) {
    if !sdl3.GL_MakeCurrent(parent.source, parent.renderer.ctx) {
        return RendererError { .BackendFailedToBindRenderingContext, sdl3.GetError() }
    }

    return nil
}

renderer_set_clear_color :: proc(renderer: ^Renderer, color: glsl.vec4) {
    gl.ClearColor(color.r, color.g, color.b, color.a)
}

renderer_clear_color_buffer :: proc(renderer: ^Renderer, color: Maybe(glsl.vec4)) {
    if color != nil {
        renderer_set_clear_color(renderer, color.(glsl.vec4))
    }

    gl.Clear(gl.COLOR_BUFFER_BIT)
}