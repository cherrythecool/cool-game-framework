package sound

import "core:log"
import "vendor:sdl3"

Device :: struct {
    id: sdl3.AudioDeviceID,
    spec: sdl3.AudioSpec,
}

device_init :: proc(sample_rate: i32 = 48_000, channels: i32 = 2) -> union { Device, cstring } {
    device := Device {
        spec = sdl3.AudioSpec {
            format = .F32,
            channels = channels,
            freq = sample_rate,
        }
    }

    device.id = sdl3.OpenAudioDevice(sdl3.AUDIO_DEVICE_DEFAULT_PLAYBACK, &device.spec)
    if device.id == 0 {
        return sdl3.GetError()
    }

    return device
}

device_deinit :: proc(device: ^Device) {
    if device.id != 0 {
        sdl3.CloseAudioDevice(device.id)
        device.id = 0
    }
}

device_resume_playback :: proc(device: ^Device) {
    if device.id != 0 && !sdl3.ResumeAudioDevice(device.id) {
        log.warnf("Failed to resume SDL3 Audio Device: %s", sdl3.GetError())
    }
}

device_pause_playback :: proc(device: ^Device) {
    if device.id != 0 && !sdl3.PauseAudioDevice(device.id) {
        log.warnf("Failed to pause SDL3 Audio Device: %s", sdl3.GetError())
    }
}