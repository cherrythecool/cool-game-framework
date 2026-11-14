package engine

import "core:fmt"
import "core:strings"

import lua "vendor:lua/5.4"

Script :: struct {
    state: ^lua.State,
    path: string,
}

@(private) SCRIPT_LIB_BINDINGS := []lua.L_Reg {
    {"newSprite", lua_new_sprite},
    {"getTexture", lua_get_texture},
    {"pushObject", lua_push_object},
    {"playSound", lua_play_sound},
    {nil, nil},
}

script_init :: proc(path: string, default_lib := true) -> (script: Script) {
    script.state = lua.L_newstate()
    if default_lib do lua.L_openlibs(script.state)
    script_load_binds(&script)
    script.path = path
    cpath := strings.clone_to_cstring(path, context.temp_allocator)
    lua.L_dofile(script.state, cpath)
    return
}

script_deinit :: proc(script: ^Script) {
    lua.close(script.state)
}

script_load_binds :: proc(script: ^Script) {
    lua.L_newlib(script.state, SCRIPT_LIB_BINDINGS)
    lua.setglobal(script.state, "cosmo")
}

ScriptCallArgument :: union {
    lua.Integer,
    lua.Number,
    cstring,
    bool,
    rawptr,
    []ScriptCallArgument,
}

push_nil :: proc(script: ^Script) {
    lua.pushnil(script.state)
}

push_integer :: proc(script: ^Script, integer: lua.Integer) {
    lua.pushinteger(script.state, integer)
}

push_number :: proc(script: ^Script, number: lua.Number) {
    lua.pushnumber(script.state, number)
}

push_cstring :: proc(script: ^Script, cstr: cstring) {
    lua.pushstring(script.state, cstr)
}

push_bool :: proc(script: ^Script, boolean: bool) {
    lua.pushboolean(script.state, auto_cast boolean)
}

push_rawptr :: proc(script: ^Script, ptr: rawptr) {
    lua.pushlightuserdata(script.state, ptr)
}

push_arguments :: proc(script: ^Script, args: []ScriptCallArgument) {
    for arg in args {
        if arg == nil {
            push_argument(script)
            continue
        }

        switch value in arg {
            case lua.Integer:
                push_argument(script, value)
            case lua.Number:
                push_argument(script, value)
            case cstring:
                push_argument(script, value)
            case bool:
                push_argument(script, value)
            case rawptr:
                push_argument(script, value)
            case []ScriptCallArgument:
                push_argument(script, value)
        }
    }
}

push_argument :: proc {
    push_nil,
    push_integer,
    push_number,
    push_cstring,
    push_bool,
    push_rawptr,
    push_arguments,
}

script_call_function :: proc(script: ^Script, name: cstring, args: ..ScriptCallArgument) {
    lua.getglobal(script.state, name)

    if !lua.isfunction(script.state, -1) {
        fmt.eprintfln("script error: '%s' either is not a function or does not exist", name)
        lua.pop(script.state, 1)
        return
    }

    push_argument(script, args)

    err := lua.pcall(script.state, auto_cast len(args), 0, 0)
    handle_lua_error(script.state, err, "failed to call function: ")
}

@(private) handle_fatal_lua_error :: proc(state: ^lua.State, err: i32, msg: string) {
    if err != i32(lua.OK) {
        fmt.panicf("%s: %s", msg, lua.tostring(state, -1))
    }
}

@(private) handle_lua_error :: proc(state: ^lua.State, err: i32, msg: string) -> bool {
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

@(private="package") script_push_value :: proc {
    lua.pushboolean,
    lua.pushcfunction,
    lua.pushnil,
    lua.pushnumber,
    lua.pushstring,
}

@(private) lua_play_sound :: proc "c" (state: ^lua.State) -> i32 {
    context = App.ctx

    path := lua.L_optstring(state, 1, "assets/TestSong.ogg")
    song := sound_stream_init(path, true)
    switch &value in song {
        case SoundStream:
            sound_device_resume_playback()
        case SoundStreamInitError:
            fmt.eprintln("failed to load sound stream:", value)
    }

    return 0
}

@(private) lua_sprite_index :: proc "c" (state: ^lua.State) -> i32 {
    context = App.ctx

    // index 1 is the obj being indexed
    property := lua.L_optstring(state, 2, "")
    lua.pushstring(state, "ptr")
    lua.gettable(state, 1)
    sprite_property := cast(^GameObject) lua.touserdata(state, -1)
    sprite_data := sprite_get_data(sprite_property)

    switch property {
        case "centered":
            lua.pushboolean(state, auto_cast sprite_data.centered)
            return 1
        case "rotation":
            lua.pushnumber(state, auto_cast sprite_data.rotation)
            return 1
        case "position":
            lua.newtable(state)
            lua.pushnumber(state, auto_cast sprite_data.position.x)
            lua.seti(state, -2, 1)
            lua.pushnumber(state, auto_cast sprite_data.position.y)
            lua.seti(state, -2, 2)
            return 1
        case "scale":
            lua.newtable(state)
            lua.pushnumber(state, auto_cast sprite_data.scale.x)
            lua.seti(state, -2, 1)
            lua.pushnumber(state, auto_cast sprite_data.scale.y)
            lua.seti(state, -2, 2)
            return 1
    }

    return 0
}

@(private) lua_new_sprite :: proc "c" (state: ^lua.State) -> i32 {
    context = App.ctx

    x := lua.L_optnumber(state, 1, 0.0)
    y := lua.L_optnumber(state, 2, 0.0)
    has_texture := lua.istable(state, 3)

    texture: Maybe(^Asset) = nil
    if has_texture {
        lua.pushstring(state, "ptr")
        lua.gettable(state, 3)
        texture = cast(^Asset) lua.touserdata(state, -1)
    }

    sprite := sprite_init(texture)
    data := sprite_get_data(&sprite)
    data.position.xy = {auto_cast x, auto_cast y}
    sprite_cloned := new_clone(sprite)
    
    lua.newtable(state)
    lua.pushlightuserdata(state, sprite_cloned)
    lua.setfield(state, -2, "ptr")

    lua.newtable(state)
    lua.pushcfunction(state, lua_sprite_index)
    lua.setfield(state, -2, "__index")
    lua.setmetatable(state, -2)

    return 1
}

@(private) lua_get_texture :: proc "c" (state: ^lua.State) -> i32 {
    context = App.ctx

    path := lua.L_optstring(state, 1, "assets/dog.png")
    path_str := strings.clone_from(path)
    texture := assets_get_texture(path_str)

    if texture == nil {
        lua.pushnil(state)
    } else {
        lua.newtable(state)
        lua.pushlightuserdata(state, texture.(^Asset))
        lua.setfield(state, -2, "ptr")
    }

    return 1
}

@(private) lua_push_object :: proc "c" (state: ^lua.State) -> i32 {
    context = App.ctx

    lua.getfield(state, 1, "ptr")
    sprite_ptr := cast(^GameObject) lua.touserdata(state, -1)
    defer free(sprite_ptr)

    append(&App.current_scene.objects, sprite_ptr^)
    lua.pushlightuserdata(state, &App.current_scene.objects[len(App.current_scene.objects) - 1])
    lua.setfield(state, 1, "ptr")

    return 0
}