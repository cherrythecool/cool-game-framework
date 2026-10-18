# cherryaudio

A simple wrapper library for different audio decoding libraries to make
things easier for you.

## Supported Formats

- WAV (dr_wav)
- FLAC (dr_flac)
- MP3 (dr_mp3)
- OGG Vorbis (stb_vorbis)
- OPUS (opusfile)

## Building

All you need is a C compiler and CMake.

To build the library just build with CMake in this folder (it will output to the `build` folder),
and to build any demo just build with CMake in the directory of the demo you want.

## Library Credits

- [mackron](https://github.com/mackron)
    * [dr_libs](https://github.com/mackron/dr_libs) (used in library)
- [nothings](https://github.com/nothings)
    * [stb_vorbis](https://github.com/nothings/stb) (used in library)
- [xiph](https://github.com/xiph)
    * [opusfile](https://github.com/xiph/opusfile) (used in library)
    * [opus](https://github.com/xiph/opus) (used in library)
    * [libogg](https://github.com/xiph/ogg) (used in library)
