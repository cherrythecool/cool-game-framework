package engine

Scene :: struct {
    script: Script,
    objects: [dynamic]GameObject,
}

scene_init :: proc(script_path: Maybe(string)) -> (scene: Scene) {
    if script_path != nil {
        scene.script = script_init(script_path.(string))
        script_call_function(&scene.script, "new")
    }

    return
}

scene_deinit :: proc(scene: ^Scene) {
    if scene.script.state != nil {
        script_call_function(&scene.script, "free")
        script_deinit(&scene.script)
    }

    for i in 0..<len(scene.objects) {
        object_deinit(&scene.objects[i])
    }

    delete(scene.objects)
}

scene_ready :: proc(scene: ^Scene) {
    if scene.script.state != nil {
        script_call_function(&scene.script, "load")
    }

    for i in 0..<len(scene.objects) {
        object_ready(&scene.objects[i])
    }
}

scene_update :: proc(scene: ^Scene, delta_seconds: f64) {
    if scene.script.state != nil {
        script_call_function(&scene.script, "update", delta_seconds)
    }

    for i in 0..<len(scene.objects) {
        object_update(&scene.objects[i], delta_seconds)
    }
}

scene_draw :: proc(scene: ^Scene, renderer: ^Renderer) {
    if scene.script.state != nil {
        script_call_function(&scene.script, "draw")
    }

    for i in 0..<len(scene.objects) {
        object_draw(&scene.objects[i], renderer)
    }
}