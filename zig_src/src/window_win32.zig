const Self = @This();
const std = @import("std");
const window_global = @import("window.zig");
const windows = @import("windows.zig");
const class_name = "cgfWindow";

pub const init: Self = .{};

running: bool = false,
h_instance: windows.c.HINSTANCE = null,
hwnd: windows.c.HWND = null,
width: i64 = 0,
height: i64 = 0,

pub fn setup(self: *Self, width: i32, height: i32, initial_title: [:0]const u8) window_global.WindowSetupError!void {
    self.h_instance = windows.c.GetModuleHandleA(null);

    const wc: windows.c.WNDCLASS = .{
        .lpfnWndProc = proc,
        .hInstance = self.h_instance,
        .lpszClassName = class_name,
        .hCursor = windows.c.LoadCursorA(null, @ptrFromInt(windows.IDC_ARROW)),
    };

    _ = windows.c.RegisterClassA(&wc);

    const dw_style = windows.c.WS_OVERLAPPEDWINDOW;

    var window_rect: windows.c.RECT = .{
        .left = 0,
        .top = 0,
        .right = width,
        .bottom = height,
    };
    _ = windows.c.AdjustWindowRectEx(&window_rect, dw_style, 0, 0);

    const window_width = window_rect.right - window_rect.left;
    const window_height = window_rect.bottom - window_rect.top;

    self.hwnd = windows.c.CreateWindowExA(
        0,
        class_name,
        initial_title,
        dw_style,

        windows.c.CW_USEDEFAULT,
        windows.c.CW_USEDEFAULT,
        window_width,
        window_height,
        null,
        null,
        self.h_instance,
        self,
    );

    if (self.hwnd == null) {
        return window_global.WindowSetupError.FailedToCreateWindow;
    }

    const screen_width = windows.c.GetSystemMetrics(windows.c.SM_CXSCREEN);
    const screen_height = windows.c.GetSystemMetrics(windows.c.SM_CYSCREEN);

    _ = windows.c.SetWindowPos(
        self.hwnd,
        null,
        @divFloor(screen_width - window_width, 2),
        @divFloor(screen_height - window_height, 2),
        0,
        0,
        windows.c.SWP_NOZORDER | windows.c.SWP_NOSIZE
    );

    _ = windows.c.ShowWindow(self.hwnd, windows.c.SW_NORMAL);
    self.running = true;
}

pub fn deinit(self: *Self) void {
    if (self.hwnd != null) {
        _ = windows.c.DestroyWindow(self.hwnd);
    }
}

pub fn poll(self: *Self) bool {
    var message: windows.c.MSG = .{};
    var found_message = windows.c.PeekMessageA(&message, self.hwnd, 0, 0, windows.c.PM_REMOVE) != 0;

    if (found_message) {
        while (found_message) {
            _ = windows.c.TranslateMessage(&message); 
            _ = windows.c.DispatchMessageA(&message);

            found_message = windows.c.PeekMessageA(&message, self.hwnd, 0, 0, windows.c.PM_REMOVE) != 0;
        }

        return true;
    } else {
        return false;
    }
}

pub fn shouldClose(self: Self) bool {
    return !self.running;
}

fn proc(hwnd: windows.c.HWND, message: windows.c.UINT, w_param: windows.c.WPARAM, l_param: windows.c.LPARAM) callconv(.c) windows.c.LRESULT {
    switch (message) {
        windows.c.WM_CREATE => {
            const create_struct: ?*windows.c.CREATESTRUCTA = @ptrFromInt(@as(usize, @intCast(l_param)));
            if (create_struct) |cs| {
                _ = windows.c.SetWindowLongPtrA(hwnd, windows.c.GWLP_USERDATA, @intCast(@intFromPtr(cs.lpCreateParams)));
            }

            return 0;
        },
        windows.c.WM_CLOSE => {
            const state: ?*Self = @ptrFromInt(@as(usize, @intCast(windows.c.GetWindowLongPtrA(hwnd, windows.c.GWLP_USERDATA))));
            if (state) |s| {
                s.running = false;
            }

            _ = windows.c.DestroyWindow(hwnd);
            return 0;
        },
        windows.c.WM_SIZE => {
            const width = windows.LOWORD(l_param); //windows.c.LOWORD(l_param);
            const height = windows.HIWORD(l_param);//windows.c.HIWORD(l_param);

            const state: ?*Self = @ptrFromInt(@as(usize, @intCast(windows.c.GetWindowLongPtrA(hwnd, windows.c.GWLP_USERDATA))));
            if (state) |s| {
                s.width = width;
                s.height = height;
            }

            return 0;
        },
        else => return windows.c.DefWindowProcA(hwnd, message, w_param, l_param),
    }
}