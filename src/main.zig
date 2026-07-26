const std = @import("std");
const Io = std.Io;
const Window = @import("window_win32.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;

    var main_window = Window.init;
    try main_window.setup(1280, 720, "hello!");

    while (!main_window.shouldClose()) {
        _ = main_window.poll();
    }
}
