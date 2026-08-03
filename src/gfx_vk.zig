const Self = @This();
const std = @import("std");
const vk = @import("vulkan.zig").c;
const gfx = @import("gfx.zig");

pub const init: Self = .{};

context: vk.GladVulkanContext = .{},
instance: vk.VkInstance = undefined,

pub fn setup(self: *Self, name: [*c]const u8) gfx.GFXSetupError!void {
    const vk_version = vk.gladLoaderLoadVulkanContext(&self.context, null, null, null);
    if (vk_version == 0) {
        std.log.err("Failed to load a Vulkan 1.0 Context", .{});
        return gfx.GFXSetupError.FailedToLoadAPIHandles;
    }

    const app_info: vk.VkApplicationInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .apiVersion = vk.VK_API_VERSION_1_0,
        .pApplicationName = name,
        .pEngineName = "cool-game-framework",
    };

    const create_info: vk.VkInstanceCreateInfo = .{
        .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
    };

    var instance: vk.VkInstance = undefined;
    const create_result = self.context.CreateInstance.?(&create_info, null, &instance);
    if (create_result != vk.VK_SUCCESS) {
        std.log.err("Failed to create Vulkan Instance, error: {}", .{create_result});
        return gfx.GFXSetupError.FailedToInitializeInstance;
    }
}

pub fn deinit(self: *Self) void {
    if (self.context.CreateInstance != null) {
        vk.gladLoaderUnloadVulkanContext(&self.context);
    }
}