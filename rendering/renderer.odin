package rendering

import "core:fmt"
import "core:math/linalg/glsl"
import "vendor:sdl3"
import gl "vendor:OpenGL"

Renderer :: struct {
    ctx: sdl3.GLContext,

    default_quad: Mesh,
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

renderer_deinit :: proc(display: ^Display) {
    renderer_bind(display)
    mesh_deinit(&display.renderer.default_quad)

    sdl3.GL_DestroyContext(display.renderer.ctx)
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

renderer_make_quad :: proc(display: ^Display) -> Mesh {
    renderer_bind(display)

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

    mesh := mesh_init(quad_vertices, quad_indices, {
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

    return mesh
}