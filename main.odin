package main

import "core:strings"
import "base:runtime"

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:mem"

import lua "vendor:lua/5.4"

import "engine"

handle_fatal_lua_error :: proc(state: ^lua.State, err: i32, msg: string) {
    if err != i32(lua.OK) {
        fmt.panicf("%s: %s", msg, lua.tostring(state, -1))
    }
}

handle_lua_error :: proc(state: ^lua.State, err: i32, msg: string) -> bool {
    if err != i32(lua.OK) {
        fmt.eprintfln("%s: %s", msg, lua.tostring(state, -1))
        return false
    } else {
        return true
    }
}

lua_call_function_empty :: proc(state: ^lua.State, name: cstring) -> bool {
    lua.getglobal(state, name)

    if !lua.isfunction(state, -1) {
        fmt.eprintfln("lua error: '%s' either is not a function or does not exist", name)
        lua.pop(state, 1)
        return false
    } else {
        err := lua.pcall(state, 0, 0, 0)
        handle_lua_error(state, err, "failed to call function: ")
        return err == i32(lua.OK)
    }
}

lua_new_sprite :: proc "c" (state: ^lua.State) -> i32 {
    context = engine.App.ctx

    x := lua.L_optnumber(state, 1, 0.0)
    y := lua.L_optnumber(state, 2, 0.0)
    has_texture := lua.istable(state, 3)

    texture: Maybe(^engine.Asset) = nil
    if has_texture {
        lua.pushstring(state, "ptr")
        lua.gettable(state, 3)
        texture = cast(^engine.Asset) lua.touserdata(state, -1)
    }

    sprite := engine.sprite_init(texture)
    data := engine.sprite_get_data(&sprite)
    data.position.xy = {auto_cast x, auto_cast y}
    sprite_cloned := new_clone(sprite)
    
    lua.newtable(state)
    lua.pushlightuserdata(state, sprite_cloned)
    lua.setfield(state, -2, "ptr")

    return 1
}

lua_get_texture :: proc "c" (state: ^lua.State) -> i32 {
    context = engine.App.ctx

    path := lua.L_optstring(state, 1, "assets/dog.png")
    path_str := strings.clone_from(path)
    texture := engine.assets_get_texture(path_str)

    if texture == nil {
        lua.pushnil(state)
    } else {
        lua.newtable(state)
        lua.pushlightuserdata(state, texture.(^engine.Asset))
        lua.setfield(state, -2, "ptr")
    }

    return 1
}

lua_push_object :: proc "c" (state: ^lua.State) -> i32 {
    context = engine.App.ctx

    lua.getfield(state, 1, "ptr")
    sprite_ptr := cast(^engine.GameObject) lua.touserdata(state, -1)
    defer free(sprite_ptr)

    append(&engine.App.current_scene.objects, sprite_ptr^)
    lua.pushlightuserdata(state, &engine.App.current_scene.objects[len(engine.App.current_scene.objects) - 1])
    lua.setfield(state, 1, "ptr")

    return 0
}

main :: proc() {
    app_result := engine.app_init({
        title = "cosmo(s)",
        content_size = { 1280, 720 },
        vsync = true,
    })
    context = engine.App.ctx

    defer engine.app_deinit()

    switch result in app_result {
        case engine.AppError:
            fmt.panicf("Failed to initialize app, error: %v", result)
        case engine.DisplayError:
            fmt.panicf("Failed to initialize app display, error: %v", result)
        case engine.RendererError:
            fmt.panicf("Failed to initialize app renderer, error: %v", result)
    }

    state := lua.L_newstate()
    defer lua.close(state)
    lua.L_openlibs(state)

    lua.newtable(state)
    lua.pushcfunction(state, lua_new_sprite)
    lua.setfield(state, 1, "newSprite")
    lua.pushcfunction(state, lua_get_texture)
    lua.setfield(state, 1, "getTexture")
    lua.pushcfunction(state, lua_push_object)
    lua.setfield(state, 1, "pushObject")
    lua.setglobal(state, "cosmo")

    handle_fatal_lua_error(state, lua.L_dofile(state, "game/test_scene.lua"), "failed to load lua file")

    lua_call_function_empty(state, "new")
    defer lua_call_function_empty(state, "free")
    lua_call_function_empty(state, "load")

    engine.app_run()
}