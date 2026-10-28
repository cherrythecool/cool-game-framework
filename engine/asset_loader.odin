package engine

import "core:mem"
import "core:fmt"
import "core:strings"
import "core:os"

Asset :: struct {
    data: union {
        Texture,
        ShaderProgram,
        SoundStream,
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

assets_init :: proc() {
    loader.assets = make(map[string]^Asset)
}

assets_deinit :: proc() {
    for key in loader.assets {
        assets_release(loader.assets[key])
    }

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
            deleted_key, _ := delete_key(&loader.assets, key.(string))

            // sometimes you might heap allocate or stack allocate a string
            // and when the key is deleted that string may need to be freed
            // so if that is needed (determined with info) then it will be!
            key_info := mem.query_info(raw_data(deleted_key), context.allocator)
            if key_info.size != nil {
                delete(deleted_key)
            }
        } else {
            fmt.eprintfln("bug: released an asset that is not in the map (%p)", asset)
        }

        switch &data in asset.data {
            case Texture:
                texture_deinit(data)
            case ShaderProgram:
                shader_free(&data)
            case SoundStream:
                sound_stream_deinit(&data)
        }

        free(asset)
    }
}

assets_check :: proc(key: string, $T: typeid) -> union { ^Asset, bool } {
    if key in loader.assets {
        _, is_type := loader.assets[key].data.(T)
        if is_type {
            return loader.assets[key]
        } else {
            return true
        }
    }

    return false
}

assets_get_texture :: proc(path: string) -> Maybe(^Asset) {
    asset_or_exists := assets_check(path, Texture)

    switch value in asset_or_exists {
        case ^Asset:
            value.references += 1
            return value
        case bool:
            // in case the asset at the given key isn't the right type
            if value {
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
    asset_or_exists := assets_check(id, ShaderProgram)

    switch value in asset_or_exists {
        case ^Asset:
            value.references += 1
            return value
        case bool:
            // in case the asset at the given key isn't the right type
            if value {
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

assets_get_sound_stream :: proc(path: string) -> Maybe(^Asset) {
    asset_or_exists := assets_check(path, SoundStream)

    switch value in asset_or_exists {
        case ^Asset:
            value.references += 1
            return value
        case bool:
            // in case the asset at the given key isn't the right type
            if value {
                return nil
            }
    }

    asset := new(Asset)

    cstring_path := strings.clone_to_cstring(path)
    defer delete(cstring_path)

    sound_stream_result := sound_stream_init(cstring_path)
    switch result in sound_stream_result {
        case SoundStream:
            asset.references += 1
            asset.data = result
            loader.assets[path] = asset
        case SoundStreamInitError:
            fmt.eprintfln("Failed to init sound stream, error: %v", result)
            return nil
    }

    return asset
}