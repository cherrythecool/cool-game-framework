package engine

import gl "vendor:OpenGL"

Mesh :: struct {
    vao, vbo, ebo: u32,
    indice_count: i32,
}

MeshVertexType :: enum u32 {
    F32 = gl.FLOAT,
}

MeshVertexSpec :: struct {
    count: i32,
    type: MeshVertexType,
    normalize: bool,
    bytes_between_each: i32,
    bytes_from_each: uintptr,
}

mesh_init :: proc(vertices: []f32, indices: []u32, vertex_specs: []MeshVertexSpec) -> Mesh {
    mesh: Mesh
    
    gl.GenBuffers(1, &mesh.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), raw_data(vertices), gl.STATIC_DRAW)
    
    mesh.indice_count = i32(len(indices))
    gl.GenBuffers(1, &mesh.ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indices), raw_data(indices), gl.STATIC_DRAW)
    
    gl.GenVertexArrays(1, &mesh.vao)
    gl.BindVertexArray(mesh.vao)

    for i in 0..<len(vertex_specs) {
        spec := vertex_specs[i]
        gl.VertexAttribPointer(u32(i), spec.count, u32(spec.type), spec.normalize, spec.bytes_between_each, spec.bytes_from_each)
        gl.EnableVertexAttribArray(u32(i))
    }

    return mesh
}

mesh_deinit :: proc(mesh: ^Mesh) {
    gl.DeleteBuffers(1, &mesh.ebo)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteVertexArrays(1, &mesh.vao)
}

mesh_bind :: proc(mesh: Mesh) {
    gl.BindVertexArray(mesh.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
}

mesh_draw :: proc(mesh: Mesh) {
    mesh_bind(mesh)
    gl.DrawElements(gl.TRIANGLES, mesh.indice_count, gl.UNSIGNED_INT, nil)
}