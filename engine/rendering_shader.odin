package engine

import "core:strings"
import "core:os"

import gl "vendor:OpenGL"
import "core:math/linalg/glsl"

ShaderProgram :: struct {
    program: u32,
    uniform_locations: map[string]i32,
}

shader_get_uniform_location :: proc(program: ^ShaderProgram, name: cstring) -> i32 {
    name_str := string(name)
    if name_str not_in program.uniform_locations {
        program.uniform_locations[name_str] = gl.GetUniformLocation(program.program, name)
    }

    return program.uniform_locations[name_str]
}

shader_get_uniform_mat4 :: proc(program: ^ShaderProgram, name: cstring) -> glsl.mat4 {
    location := shader_get_uniform_location(program, name)
    mat: glsl.mat4
    gl.GetUniformfv(program.program, location, raw_data(&mat))
    return mat
}

shader_get_uniform :: proc {
    shader_get_uniform_mat4
}

shader_set_uniform_mat4 :: proc(program: ^ShaderProgram, name: cstring, value: glsl.mat4) {
    local_value := value
    gl.UniformMatrix4fv(shader_get_uniform_location(program, name), 1, false, raw_data(&local_value))
}

shader_set_uniform_f32 :: proc(program: ^ShaderProgram, name: cstring, value: f32) {
    gl.Uniform1f(shader_get_uniform_location(program, name), value)
}

shader_set_uniform :: proc {
    shader_set_uniform_mat4,
    shader_set_uniform_f32
}

shader_bind :: proc(program: ShaderProgram) {
    if program.program == 0 {
        return
    }

    gl.UseProgram(program.program)
}

ShaderLoadErrorType :: enum {
    FileDoesNotExist,
}

ShaderLoadError :: struct {
    type: ShaderLoadErrorType,
    message: string,
}

ShaderLoadResult :: union {
    ShaderProgram, ShaderCompileError, ShaderLoadError, os.Error,
}

shader_load :: proc(fragment_path: string, vertex_path: string) -> ShaderLoadResult {
    if !os.exists(fragment_path) {
        return ShaderLoadError { .FileDoesNotExist, fragment_path }
    }

    if !os.exists(vertex_path) {
        return ShaderLoadError { .FileDoesNotExist, vertex_path }
    }

    allocator := context.allocator
    fragment_bytes, fragment_err := os.read_entire_file(fragment_path, allocator)
    if fragment_err != nil {
        return fragment_err
    }

    defer delete(fragment_bytes, allocator)

    vertex_bytes, vertex_err := os.read_entire_file(vertex_path, allocator)
    if vertex_err != nil {
        return vertex_err
    }

    defer delete(vertex_bytes, allocator)

    fragment_string := strings.clone_to_cstring(string(fragment_bytes), allocator)
    defer delete(fragment_string, allocator)

    vertex_string := strings.clone_to_cstring(string(vertex_bytes), allocator)
    defer delete(vertex_string, allocator)

    compile_result := shader_compile(&fragment_string, &vertex_string)
    switch result in compile_result {
        case ShaderProgram:
            return result
        case ShaderCompileError:
            return result
        case:
            return nil
    }
}

ShaderCompileErrorType :: enum {
    FragmentFailedToCompile,
    VertexFailedToCompile,
    ProgramFailedToLink,
}

ShaderCompileError :: struct {
    type: ShaderCompileErrorType,
    info: [512]u8,
}

ShaderCompileResult :: union {
    ShaderProgram, ShaderCompileError,
}

shader_compile :: proc(fragment_source: ^cstring, vertex_source: ^cstring) -> ShaderCompileResult {
    success: i32
    info_log: [512]u8

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    defer gl.DeleteShader(fragment_shader)

    gl.ShaderSource(fragment_shader, 1, fragment_source, nil)
    gl.CompileShader(fragment_shader)

    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(fragment_shader, 512, nil, &info_log[0])
        return ShaderCompileError { .FragmentFailedToCompile, info_log }
    }

    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    defer gl.DeleteShader(vertex_shader)

    gl.ShaderSource(vertex_shader, 1, vertex_source, nil)
    gl.CompileShader(vertex_shader)

    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if success == 0 {
        gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
        return ShaderCompileError { .VertexFailedToCompile, info_log }
    }

    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)

    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
    if success == 0 {
        gl.GetProgramInfoLog(shader_program, 512, nil, &info_log[0])
        return ShaderCompileError { .ProgramFailedToLink, info_log }
    }

    return ShaderProgram { shader_program, {} }
}

shader_free :: proc(shader_program: ^ShaderProgram) {
    gl.DeleteProgram(shader_program.program)
    delete(shader_program.uniform_locations)
}