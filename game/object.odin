package game

import "../rendering"

EmptyObject :: struct {}

GameObjectData :: union {
    EmptyObject,
    Sprite,
}

GameObject :: struct {
    data: GameObjectData,

    ready: proc(^GameObject),
    update: proc(^GameObject, f64),
    draw: proc(^GameObject, ^rendering.Renderer),
    deinit: proc(^GameObject),
}

object_ready :: proc(object: ^GameObject) {
    if object.ready != nil {
        object.ready(object)
    }
}

object_update :: proc(object: ^GameObject, delta_seconds: f64) {
    if object.update != nil {
        object.update(object, delta_seconds)
    }
}

object_draw :: proc(object: ^GameObject, renderer: ^rendering.Renderer) {
    if object.draw != nil {
        object.draw(object, renderer)
    }
}

object_deinit :: proc(object: ^GameObject) {
    if object.deinit != nil {
        object.deinit(object)
    }
}