const std = @import("std");
const Io = std.Io;
const Window = @import("window_win32.zig");

const glad = @import("glad");

pub fn main(init: std.process.Init) !void {
    _ = init;

    var context: glad.GladVulkanContext = .{};
    const vk_version = glad.gladLoaderLoadVulkanContext(&context, null, null, null);
    if (vk_version == 0) {
        std.log.err("Failed to load a Vulkan 1.0 Context", .{});
        return error.VulkanInitFailed;
    }

    std.log.info("Vulkan Version Initialized: {}", .{vk_version});

    const vkCreateInstance = context.CreateInstance.?;

    const app_info: glad.VkApplicationInfo = .{
        .sType = glad.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .apiVersion = glad.VK_API_VERSION_1_0,
        .pApplicationName = "hi",
        .pEngineName = "cgf",
    };

    const create_info: glad.VkInstanceCreateInfo = .{
        .sType = glad.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
    };

    var instance: glad.VkInstance = undefined;
    const create_result = vkCreateInstance(&create_info, null, &instance);
    if (create_result != glad.VK_SUCCESS) {
        std.log.err("Failed to create Vulkan Instance, error: {}", .{create_result});
        return error.VulkanCreateInstanceFailed;
    }

    var main_window = Window.init;
    try main_window.setup(1280, 720, "cool game");

    while (!main_window.shouldClose()) {
        _ = main_window.poll();
    }
}
