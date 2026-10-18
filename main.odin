package main

import "base:runtime"

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:mem"

import "engine"

main :: proc() {
    // https://gist.github.com/karl-zylinski/4ccf438337123e7c8994df3b03604e33
    when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations leaked: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}

			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}

			mem.tracking_allocator_destroy(&track)
		}
	}

    context.logger = log.create_console_logger()

    app: engine.App
    app_result := engine.app_init({
        title = "cgf version idek",
        content_size = { 1280, 720 },
        vsync = true,
    })
    defer engine.app_deinit(&app)

    switch result in app_result {
        case engine.App:
            app = result
        case engine.AppError:
            fmt.panicf("Failed to initialize app, error: %v", result)
        case engine.DisplayError:
            fmt.panicf("Failed to initialize app display, error: %v", result)
        case engine.RendererError:
            fmt.panicf("Failed to initialize app renderer, error: %v", result)
    }

    song: engine.CherryStream
    song_result := engine.stream_init(&app.device, "assets/TestSong.ogg")
    defer engine.stream_deinit(&song)
    
    switch result in song_result {
        case engine.CherryStream:
            song = result
        case cstring:
            log.warnf("Failed to load song, error: %s", result)
    }

    engine.device_resume_playback(&app.device)

    for i in 0..<5 {
        dog_sprite := engine.sprite_init("assets/Dog.png")
        dog_data := engine.sprite_get_data(&dog_sprite)
        dog_data.position = {f32(i * 300) + rand.float32_range(-64, 64), rand.float32_range(0, 720)}
        dog_data.rotation = rand.float32_range(-180, 180)
        append(&app.current_scene.objects, dog_sprite)
    }

    engine.app_run(&app)
}