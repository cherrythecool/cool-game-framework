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

    const glad_lib = b.addLibrary(.{
        .name = "glad",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    glad_lib.root_module.addIncludePath(b.path("src/glad_vk/include/"));
    glad_lib.root_module.addCSourceFile(.{
        .file = b.path("src/glad_vk/src/vulkan.c"),
        .language = .c,
    });

    const glad_translation = b.addTranslateC(.{
        .root_source_file = b.path("src/glad_vk/include/glad/vulkan.h"),
        .target = target,
        .optimize = optimize,
    });

    glad_translation.addIncludePath(b.path("src/glad_vk/include/"));

    const glad_mod = glad_translation.createModule();
    glad_mod.linkLibrary(glad_lib);

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
                .{
                    .name = "glad",
                    .module = glad_mod,
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
