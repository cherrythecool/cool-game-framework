const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const win32_translation = b.addTranslateC(.{
        .root_source_file = b.path("src/win32.h"),
        .target = target,
        .optimize = optimize,
    });

    win32_translation.linkSystemLibrary("User32", .{
        .needed = true,
    });

    var exe = b.addExecutable(.{
        .name = "cool_game_framework",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "win32",
                    .module = win32_translation.createModule(),
                },
            },
        }),
    });

    if (optimize != .Debug) {
        exe.subsystem = .windows;
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
