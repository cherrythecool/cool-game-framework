package engine

import "core:fmt"
import "core:strings"
import "core:os"

Asset :: struct {
    data: union {
        Texture,
        ShaderProgram,
    },
    references: u64,
}

AssetLoader :: struct {
    assets: map[string]^Asset,
}

@(private) loader: AssetLoader

@(private) get_path_from_asset :: proc(target: ^Asset) -> union { string } {
    for key, value in loader.assets {
        if value == target {
            return key
        }
    }

    return nil
}

assets_deinit :: proc() {
    delete(loader.assets)
}

assets_release :: proc(asset: ^Asset) {
    if asset.references > 0 {
        asset.references -= 1
    } else {
        fmt.eprintln("bug: asset released when already at 0 references, should not be possible")
    }

    if asset.references == 0 {
        key := get_path_from_asset(asset)
        if key != nil {
            delete_key(&loader.assets, key.(string))
        } else {
            fmt.eprintfln("bug: released an asset that is not in the map (%p)", asset)
        }

        switch &data in asset.data {
            case Texture:
                texture_deinit(data)
            case ShaderProgram:
                shader_free(&data)
        }

        free(asset)
    }
}

assets_get_texture :: proc(path: string) -> Maybe(^Asset) {
    if path in loader.assets {
        _, is_texture := loader.assets[path].data.(Texture)
        if is_texture {
            loader.assets[path].references += 1
            return loader.assets[path]
        } else {
            return nil
        }
    }

    c_path := strings.clone_to_cstring(path)
    texture_result := texture_load(c_path)
    delete(c_path)

    asset := new(Asset)
    switch result in texture_result {
        case Texture:
            asset.references += 1
            asset.data = result
            loader.assets[path] = asset
        case TextureLoadError:
            fmt.eprintfln("error: texture failed to load with error %v", result)
            return nil
    }

    return asset
}

assets_get_shader :: proc(id: string, fragment_path: string, vertex_path: string) -> Maybe(^Asset) {
    if id in loader.assets {
        _, is_shader := loader.assets[id].data.(ShaderProgram)
        if is_shader {
            loader.assets[id].references += 1
            return loader.assets[id]
        } else {
            return nil
        }
    }

    asset := new(Asset)

    shader_result := shader_load(fragment_path, vertex_path)
    switch result in shader_result {
        case ShaderProgram:
            asset.references += 1
            asset.data = result
            loader.assets[id] = asset
        case ShaderCompileError:
            fmt.eprintfln("Failed to compile shader, error: %v", result)
            return nil
        case ShaderLoadError:
            fmt.eprintfln("Failed to load shader, error: %v", result)
            return nil
        case os.Error:
            fmt.eprintfln("Failed to read file from os, error: %v", result)
            return nil
    }

    return asset
}