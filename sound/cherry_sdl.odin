package sound

import "core:mem"
import "base:runtime"

import "core:c"
import "core:log"

import "vendor:sdl3"

import "../vendor/cherryaudio"

CherryStream :: struct {
    internal_streamer: ^cherryaudio.Stream,
    output_stream: ^sdl3.AudioStream,
}

cherry_sdl_callback :: proc "c" (userdata: rawptr, stream: ^sdl3.AudioStream, additional_amount: c.int, total_amount: c.int) {
    properties := sdl3.GetAudioStreamProperties(stream)
    if sdl3.GetBooleanProperty(properties, "paused", false) {
        return
    }

    cherry_stream := (^cherryaudio.Stream)(userdata)
    pcm := cherryaudio.decode_samples(cherry_stream^, .F32, cherryaudio.Size(additional_amount))
    defer cherryaudio.free(pcm.data)
    
    if sdl3.GetBooleanProperty(properties, "loop", false) {
        if pcm.size < cherryaudio.Size(additional_amount) {
            cherryaudio.stream_seek_to_sample(cherry_stream^, 0)
        }
    }

    volume := sdl3.GetFloatProperty(properties, "volume", 1.0)
    if volume != 1.0 && pcm.size > 0 && pcm.data != nil {
        pcm_len := pcm.size / size_of(f32)
        pcm_frames := mem.slice_ptr((^f32)(pcm.data), int(pcm_len))

        for i in 0..<pcm_len {
            pcm_frames[i] *= volume
        }
    }
    
    if !sdl3.PutAudioStreamData(stream, pcm.data, i32(pcm.size)) {
        sdl3.Log("Failed to push audio stream data: %s", sdl3.GetError())
    }
}

stream_init :: proc(target_device: ^Device, file_path: cstring, loop: bool = false) -> union { CherryStream, cstring } {
    raw_stream := cherryaudio.stream_file(file_path, .DETECT)
    if raw_stream.meta.sample_rate == 0 {
        return "Failed to load file with cherryaudio!"
    }

    stream_ptr := new_clone(raw_stream)

    stream := CherryStream {
        internal_streamer = stream_ptr,
    }

    src_spec := sdl3.AudioSpec {
        format = .F32,
        channels = i32(stream_ptr.meta.channels),
        freq = i32(stream_ptr.meta.sample_rate),
    }

    stream.output_stream = sdl3.CreateAudioStream(&src_spec, &target_device.spec)
    if stream.output_stream == nil {
        return sdl3.GetError()
    }

    sdl3.SetAudioStreamGetCallback(stream.output_stream, cherry_sdl_callback, stream_ptr)
    
    if !sdl3.BindAudioStream(target_device.id, stream.output_stream) {
        return sdl3.GetError()
    }

    properties := sdl3.GetAudioStreamProperties(stream.output_stream)
    sdl3.SetBooleanProperty(properties, "paused", false)
    sdl3.SetBooleanProperty(properties, "loop", loop)
    sdl3.SetFloatProperty(properties, "volume", 0.5)

    return stream
}

stream_deinit :: proc(stream: ^CherryStream) {
    if stream.output_stream != nil {
        sdl3.DestroyAudioStream(stream.output_stream)
        stream.output_stream = nil
    }

    if stream.internal_streamer != nil {
        free(stream.output_stream)
    }
}

stream_is_paused :: proc(stream: ^CherryStream) -> bool {
    if stream.output_stream != nil {
        properties := sdl3.GetAudioStreamProperties(stream.output_stream)
        return sdl3.GetBooleanProperty(properties, "paused", false)
    }

    return false
}

stream_set_paused :: proc(stream: ^CherryStream, paused: bool) {
    if stream.output_stream != nil {
        properties := sdl3.GetAudioStreamProperties(stream.output_stream)
        sdl3.SetBooleanProperty(properties, "paused", paused)
    }
}