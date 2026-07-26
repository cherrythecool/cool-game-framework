const window_global = @import("window.zig");
const windows = @import("windows.zig");
const Self = @This();
const class_name = "cgfWindow";

pub const init: Self = .{};

running: bool = false,
h_instance: windows.c.HINSTANCE = null,
hwnd: windows.c.HWND = null,

pub fn setup(self: *Self, width: i32, height: i32, initial_title: [:0]const u8) window_global.WindowSetupError!void {
    self.h_instance = windows.c.GetModuleHandleA(null);

    const wc: windows.c.WNDCLASS = .{
        .lpfnWndProc = proc,
        .hInstance = self.h_instance,
        .lpszClassName = class_name,
        .hCursor = windows.c.LoadCursorA(null, @ptrFromInt(windows.IDC_ARROW)),
    };

    _ = windows.c.RegisterClassA(&wc);

    self.hwnd = windows.c.CreateWindowExA(
        0,
        class_name,
        initial_title,
        windows.c.WS_OVERLAPPEDWINDOW,

        windows.c.CW_USEDEFAULT,
        windows.c.CW_USEDEFAULT,
        width,
        height,
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
        @divFloor(screen_width - width, 2),
        @divFloor(screen_height - height, 2),
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

pub fn proc(hwnd: windows.c.HWND, message: windows.c.UINT, w_param: windows.c.WPARAM, l_param: windows.c.LPARAM) callconv(.c) windows.c.LRESULT {
    switch (message) {
        windows.c.WM_CREATE => {
            const state: ?*windows.c.CREATESTRUCTA = @ptrFromInt(@as(usize, @intCast(l_param)));
            if (state) |s| {
                _ = windows.c.SetWindowLongPtrA(hwnd, windows.c.GWLP_USERDATA, @intCast(@intFromPtr(s.lpCreateParams)));
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
        else => return windows.c.DefWindowProcA(hwnd, message, w_param, l_param),
    }
}