package game

import "core:fmt"
import "core:math/linalg/glsl"
import "../rendering"

Sprite :: struct {
    texture: Maybe(^Asset),
    shader: Maybe(^Asset),
    region: [4]f32,
    flipped: [2]bool,

    position: [2]f32,
    scale: [2]f32,
    origin: [2]f32,
    rotation: f32,

    offset: [2]f32,
}

sprite_init :: proc(path: string) -> GameObject {
    object := GameObject {
        data = Sprite {
            texture = assets_get_texture(path),
            shader = assets_get_shader("defaultSprite", "assets/shaders/sprite.frag", "assets/shaders/sprite.vert"),
            region = 0,
            flipped = false,

            position = 0,
            scale = 1,
            origin = 0.5,
            rotation = 0,

            offset = 0,
        },

        ready = sprite_ready,
        update = sprite_update,
        draw = sprite_draw,
        deinit = sprite_deinit,
    }

    return object
}

sprite_ready :: proc(self: ^GameObject) {}

sprite_update :: proc(self: ^GameObject, delta: f64) {}

sprite_draw :: proc(self: ^GameObject, renderer: ^rendering.Renderer) {
    sprite := self.data.(Sprite)

    if sprite.shader == nil {
        return
    }

    shader := sprite.shader.(^Asset).data.(rendering.ShaderProgram)

    rendering.shader_bind(shader)

    rendering.shader_set_uniform(&shader, "projectionMatrix", renderer.projection_matrix)

    if sprite.texture != nil {
        texture := sprite.texture.(^Asset).data.(rendering.Texture)
        rendering.texture_bind(texture)

        transform: glsl.mat4 = glsl.mat4Scale( { f32(texture.width), f32(texture.height), 1 } )
        rendering.shader_set_uniform(&shader, "modelMatrix", transform)
    }

    rendering.mesh_draw_triangles(renderer.default_quad)
}

sprite_deinit :: proc(self: ^GameObject) {
    sprite := self.data.(Sprite)

    if sprite.shader != nil {
        assets_release(sprite.shader.(^Asset))
    }

    if sprite.texture != nil {
        assets_release(sprite.texture.(^Asset))
    }
}