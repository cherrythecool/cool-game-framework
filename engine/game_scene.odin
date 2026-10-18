package engine

Scene :: struct {
    objects: [dynamic]GameObject,
}

scene_ready :: proc(scene: ^Scene) {
    for i in 0..<len(scene.objects) {
        object_ready(&scene.objects[i])
    }
}

scene_update :: proc(scene: ^Scene, delta_seconds: f64) {
    for i in 0..<len(scene.objects) {
        object_update(&scene.objects[i], delta_seconds)
    }
}

scene_draw :: proc(scene: ^Scene, renderer: ^Renderer) {
    for i in 0..<len(scene.objects) {
        object_draw(&scene.objects[i], renderer)
    }
}

scene_deinit :: proc(scene: ^Scene) {
    for i in 0..<len(scene.objects) {
        object_deinit(&scene.objects[i])
    }

    delete(scene.objects)
}