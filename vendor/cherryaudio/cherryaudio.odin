package cherryaudio

import "core:c/libc"
import "core:c"

@(private)
CHERRYAUDIO :: "src/build/cherryaudio.lib" when ODIN_OS == .Windows else "src/build/libcherryaudio.a"

@(private)
OPUS :: "src/build/vendor/opus-1.5.2/opus.lib" when ODIN_OS == .Windows else "src/build/vendor/opus-1.5.2/libopus.a"

@(private)
OPUSFILE :: "src/build/vendor/opusfile-master/opusfile.lib" when ODIN_OS == .Windows else "src/build/vendor/opusfile-master/libopusfile.a"

@(private)
OGG :: "src/build/vendor/libogg-1.3.5/ogg.lib" when ODIN_OS == .Windows else "src/build/vendor/libogg-1.3.5/libogg.a"

when !#exists(CHERRYAUDIO) || !#exists(OPUS) || !#exists(OPUSFILE) || !#exists(OGG) {
	#panic("Could not find the compiled cherryaudio library, it can be compiled by running `cmake -B build -DCMAKE_POLICY_VERSION_MINIMUM=3.5` & `cmake --build build` in the src dir")
}

foreign import lib { CHERRYAUDIO, OPUS, OPUSFILE, OGG, }

Size :: c.ulonglong

PCMFormat :: enum c.int {
    F32 = 0,
    I16 = 1,
}

FileFormat :: enum c.int {
    DETECT = 0,
    WAV = 1,
    FLAC = 2,
    MP3 = 3,
    VORBIS = 4,
    OPUS = 5,
}

Metadata :: struct {
    channels: c.uint,
    sample_rate: c.uint,
    sample_count: Size,
}

PCM :: struct {
    data: rawptr,
    size: Size,
    format: PCMFormat,
}

File :: struct {
    pcm: PCM,
    meta: Metadata,
}

Stream :: struct {
    data: rawptr,
    memory: rawptr,
    file_format: FileFormat,
    meta: Metadata,
}

@(default_calling_convention="c", link_prefix="cherry_")
foreign lib {
    load_file :: proc(path: cstring, file_format: FileFormat, requested_pcm_format: PCMFormat) -> File ---
    load_file_from_memory :: proc(memory: rawptr, size: Size, file_format: FileFormat, requested_pcm_format: PCMFormat) -> File ---

    stream_file :: proc(path: cstring, file_format: FileFormat) -> Stream ---
    stream_memory :: proc(memory: rawptr, size: Size, file_format: FileFormat) -> Stream ---
    decode_samples :: proc(stream: Stream, requested_pcm_format: PCMFormat, sample_count: Size) -> PCM ---
    stream_seek_to_sample :: proc(stream: Stream, sample: Size) ---
    stream_close :: proc(stream: Stream) ---

    file_get_length :: proc(file: File) -> c.double ---
    stream_get_length :: proc(stream: Stream) -> c.double ---
}

free :: libc.free