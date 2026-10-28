package engine

import "core:math/rand"
import "core:math"
import "core:fmt"
import "core:math/linalg/glsl"

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
    centered: bool,

    time: f64,
}

sprite_init :: proc(texture: Maybe(^Asset)) -> GameObject {
    object := GameObject {
        data = Sprite {
            texture = texture,
            shader = assets_get_shader("defaultSprite", "assets/shaders/sprite.frag", "assets/shaders/sprite.vert"),
            region = 0,
            flipped = false,

            position = 0,
            scale = 1,
            origin = 0.5,
            rotation = 0,

            offset = 0,
            centered = true,
            time = 0,
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

sprite_draw :: proc(self: ^GameObject, renderer: ^Renderer) {
    sprite := self.data.(Sprite)

    if sprite.shader == nil {
        return
    }

    shader := &(sprite.shader.(^Asset).data.(ShaderProgram))

    shader_bind(shader^)

    shader_set_uniform(shader, "projectionMatrix", renderer.projection_matrix)

    if sprite.texture != nil {
        texture := sprite.texture.(^Asset).data.(Texture)
        texture_bind(texture)

        transform: glsl.mat4 = 1
        transform *= glsl.mat4Translate( { sprite.position.x, sprite.position.y, 0 } )

        transform *= glsl.mat4Translate( { sprite.offset.x * sprite.scale.x, sprite.offset.y * sprite.scale.y, 0 } )

        if sprite.centered {
            transform *= glsl.mat4Translate({
                f32(texture.width) * sprite.scale.x * -0.5,
                f32(texture.height) * sprite.scale.y * -0.5,
                0,
            })
        }

        if sprite.rotation != 0.0 {
            transform *= glsl.mat4Translate({ 
                f32(texture.width) * sprite.origin.x * sprite.scale.x,
                f32(texture.height) * sprite.origin.y * sprite.scale.y,
                0,
            })

            transform *= glsl.mat4Rotate( { 0, 0, 1 }, math.RAD_PER_DEG * sprite.rotation )

            transform *= glsl.mat4Translate({ 
                f32(texture.width) * -sprite.origin.x * sprite.scale.x,
                f32(texture.height) * -sprite.origin.y * sprite.scale.y,
                0,
            })
        }

        transform *= glsl.mat4Scale( { f32(texture.width) * sprite.scale.x, f32(texture.height) * sprite.scale.y, 1 } )

        shader_set_uniform(shader, "modelMatrix", transform)
    }

    mesh_draw(renderer.default_quad)
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

sprite_get_data :: #force_inline proc(self: ^GameObject) -> ^Sprite {
    return &(self.data.(Sprite))
}