package rendering

import "core:c"

import "vendor:sdl3"
import "vendor:sdl3/image"
import gl "vendor:OpenGL"

Texture :: struct {
    width: c.int,
    height: c.int,
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
    surface := sdl3.LoadSurface(path)
    if surface == nil {
        surface = image.Load(path)

        if surface == nil {
            return TextureLoadError { .BackendFailedToLoadImage, sdl3.GetError() }
        }
    }

    defer sdl3.DestroySurface(surface)

    if surface.format != .RGBA8888 && surface.format != .RGB24 {
        new_surface := sdl3.ConvertSurface(surface, .RGBA8888)
        if new_surface == nil {
            return TextureLoadError { .BackendFailedToConvertImage, sdl3.GetError() }
        }

        sdl3.DestroySurface(surface)
        surface = new_surface
    }

    texture: Texture
    texture.width = surface.w
    texture.height = surface.h

    gl.GenTextures(1, &texture.id)

    texture_bind(texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

    // TODO: Option for loading and/or generating mipmaps
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    #partial switch surface.format {
        case .RGB24:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, surface.w, surface.h, 0, gl.RGB, gl.UNSIGNED_BYTE, surface.pixels)
        case .RGBA8888:
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, surface.w, surface.h, 0, gl.RGBA, gl.UNSIGNED_BYTE, surface.pixels)
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