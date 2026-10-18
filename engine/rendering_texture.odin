package engine

import "core:c"

import stbi "vendor:stb/image"
import gl "vendor:OpenGL"

Texture :: struct {
    width: c.int,
    height: c.int,
    channels: c.int,
    id: u32,
}

TextureLoadErrorType :: enum {
    BackendFailedToLoadImage,
    BackendFailedToConvertImage,
    UnsupportedImageFormat,
}

TextureLoadError :: struct {
    type: TextureLoadErrorType,
    message: cstring,
}

TextureLoadResult :: union {
    Texture, TextureLoadError,
}

texture_load :: proc(path: cstring) -> TextureLoadResult {
    texture: Texture
    pixels := stbi.load(path, &texture.width, &texture.height, &texture.channels, 0)
    defer stbi.image_free(pixels)

    gl.GenTextures(1, &texture.id)

    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    // TODO: Option for loading and/or generating mipmaps
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)

    switch texture.channels {
        case 1:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, texture.width, texture.height, 0, gl.RED, gl.UNSIGNED_BYTE, pixels)
        case 2:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RG, texture.width, texture.height, 0, gl.RG, gl.UNSIGNED_BYTE, pixels)
        case 3:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, texture.width, texture.height, 0, gl.RGB, gl.UNSIGNED_BYTE, pixels)
        case 4:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.width, texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, pixels)
        case:
            return TextureLoadError { .UnsupportedImageFormat, nil }
    }

    texture_reset_bind()
    return texture
}

texture_deinit :: proc(texture: Texture) {
    id := texture.id
    gl.DeleteTextures(1, &id)
}

texture_bind :: proc(texture: Texture) {
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture.id)
}

texture_reset_bind :: proc() {
    gl.BindTexture(gl.TEXTURE_2D, 0)
}