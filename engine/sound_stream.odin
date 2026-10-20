package engine

import "core:c"
import "vendor:sdl3"

import "vendor/cherryaudio"

SoundStream :: struct {
    internal_streamer: ^cherryaudio.Stream,
    output_stream: ^sdl3.AudioStream,
}

SoundStreamInitError :: enum {
    BackendFailedToLoad,
    FailedToCreateAudioStream,
    FailedToBindAudioStream,
}

sound_stream_sdl_callback :: proc "c" (userdata: rawptr, stream: ^sdl3.AudioStream, additional_amount: c.int, total_amount: c.int) {
    cherry_stream := (^cherryaudio.Stream)(userdata)
    pcm := cherryaudio.decode_samples(cherry_stream^, .F32, cherryaudio.Size(additional_amount))
    defer cherryaudio.free(pcm.data)
    
    properties := sdl3.GetAudioStreamProperties(stream)
    if sdl3.GetBooleanProperty(properties, "loop", false) {
        if pcm.size < cherryaudio.Size(additional_amount) {
            cherryaudio.stream_seek_to_sample(cherry_stream^, 0)
        }
    }
    
    if !sdl3.PutAudioStreamData(stream, pcm.data, i32(pcm.size)) {
        sdl3.Log("Failed to push audio stream data: %s", sdl3.GetError())
    }
}

sound_stream_init :: proc(target_device: ^SoundDevice, file_path: cstring, loop: bool = false) -> union { SoundStream, SoundStreamInitError } {
    raw_stream := cherryaudio.stream_file(file_path, .DETECT)
    if raw_stream.meta.sample_rate == 0 {
        return .BackendFailedToLoad
    }

    stream_ptr := new_clone(raw_stream)

    stream := SoundStream {
        internal_streamer = stream_ptr,
    }

    src_spec := sdl3.AudioSpec {
        format = .F32,
        channels = i32(stream_ptr.meta.channels),
        freq = i32(stream_ptr.meta.sample_rate),
    }

    stream.output_stream = sdl3.CreateAudioStream(&src_spec, &target_device.spec)
    if stream.output_stream == nil {
        return .FailedToCreateAudioStream
    }

    sdl3.SetAudioStreamGetCallback(stream.output_stream, sound_stream_sdl_callback, stream_ptr)
    
    if !sdl3.BindAudioStream(target_device.id, stream.output_stream) {
        return .FailedToBindAudioStream
    }

    properties := sdl3.GetAudioStreamProperties(stream.output_stream)
    sdl3.SetBooleanProperty(properties, "loop", loop)

    return stream
}

sound_stream_deinit :: proc(stream: ^SoundStream) {
    if stream.output_stream != nil {
        sdl3.DestroyAudioStream(stream.output_stream)
        stream.output_stream = nil
    }

    if stream.internal_streamer != nil {
        free(stream.internal_streamer)
    }
}

sound_stream_set_paused :: proc(stream: ^SoundStream, paused: bool) {
    if stream.output_stream != nil {
        if paused {
            sdl3.PauseAudioStreamDevice(stream.output_stream)
        } else {
            sdl3.ResumeAudioStreamDevice(stream.output_stream)
        }
    }
}

sound_stream_is_paused :: proc(stream: ^SoundStream) -> bool {
    if stream.output_stream != nil {
        return sdl3.AudioStreamDevicePaused(stream.output_stream)
    }

    return false
}

sound_stream_set_volume :: proc(stream: ^SoundStream, volume: f32) {
    if stream.output_stream != nil {
        sdl3.SetAudioStreamGain(stream.output_stream, volume)
    }
}

sound_stream_get_volume :: proc(stream: ^SoundStream) -> union { f32 } {
    if stream.output_stream != nil {
        return sdl3.GetAudioStreamGain(stream.output_stream)
    } else {
        return nil
    }
}

sound_stream_set_speed_scale :: proc(stream: ^SoundStream, speed_scale: f32) {
    if stream.output_stream != nil {
        sdl3.SetAudioStreamFrequencyRatio(stream.output_stream, speed_scale)
    }
}

sound_stream_get_speed_scale :: proc(stream: ^SoundStream) -> union { f32 } {
    if stream.output_stream != nil {
        return sdl3.GetAudioStreamFrequencyRatio(stream.output_stream)
    } else {
        return nil
    }
}

sound_stream_seek :: proc(stream: ^SoundStream, time_sec: f64) {
    if stream.output_stream != nil {
        sdl3.ClearAudioStream(stream.output_stream)
        sample := cast(cherryaudio.Size) (time_sec * f64(stream.internal_streamer.meta.sample_rate))
        cherryaudio.stream_seek_to_sample(stream.internal_streamer^, sample)
    }
}