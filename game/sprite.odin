package game

import "../rendering"

Sprite :: struct {
    texture: rendering.Texture,
    region: [4]f32,
    flipped: [2]bool,

    position: [2]f32,
    scale: [2]f32,
    origin: [2]f32,
    rotation: f32,

    offset: [2]f32,
}

sprite_init :: proc(texture: rendering.Texture) -> GameObject {
    object := GameObject {
        data = Sprite {
            texture = texture,
            region = 0,
            flipped = { false, false },

            position = 0,
            scale = 1,
            origin = 0.5,
            rotation = 0,

            offset = 0,
        },

        ready = sprite_ready,
        update = sprite_update,
        draw = sprite_draw,
    }

    return object
}

sprite_ready :: proc(self: ^GameObject) {}

sprite_update :: proc(self: ^GameObject, delta: f64) {}

sprite_draw :: proc(self: ^GameObject) {
    spr := self.data.(Sprite)
    rendering.texture_bind(spr.texture)
}