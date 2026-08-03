const std = @import("std");
const Io = std.Io;
const Window = @import("window_win32.zig");
const GFX = @import("gfx_vk.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;

    var gfx = GFX.init;
    try gfx.setup("cool game");
    defer gfx.deinit();

    var main_window = Window.init;
    try main_window.setup(1280, 720, "cool game");
    defer main_window.deinit();

    while (!main_window.shouldClose()) {
        _ = main_window.poll();
    }
}
