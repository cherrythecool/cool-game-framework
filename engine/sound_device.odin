package engine

import "core:log"
import "vendor:sdl3"

SoundDevice : struct {
    id: sdl3.AudioDeviceID,
    spec: sdl3.AudioSpec,
    exists: bool,
} = {}

sound_device_init :: proc(sample_rate: i32 = 48_000, channels: i32 = 2) -> union { cstring } {
    if SoundDevice.exists {
        return "SoundDevice already exists"
    }

    SoundDevice = {
        spec = sdl3.AudioSpec {
            format = .F32,
            channels = channels,
            freq = sample_rate,
        }
    }

    SoundDevice.id = sdl3.OpenAudioDevice(sdl3.AUDIO_DEVICE_DEFAULT_PLAYBACK, &SoundDevice.spec)
    if SoundDevice.id == 0 {
        return sdl3.GetError()
    }

    return nil
}

sound_device_deinit :: proc() {
    if SoundDevice.id != 0 {
        sdl3.CloseAudioDevice(SoundDevice.id)
        SoundDevice.id = 0
    }
}

sound_device_resume_playback :: proc() {
    if SoundDevice.id != 0 && !sdl3.ResumeAudioDevice(SoundDevice.id) {
        log.warnf("Failed to resume SDL3 Audio Device: %s", sdl3.GetError())
    }
}

sound_device_pause_playback :: proc() {
    if SoundDevice.id != 0 && !sdl3.PauseAudioDevice(SoundDevice.id) {
        log.warnf("Failed to pause SDL3 Audio Device: %s", sdl3.GetError())
    }
}