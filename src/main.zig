const std = @import("std");
const Io = std.Io;
const win32 = @import("win32");

const IDC_ARROW = @as(c_int, 32512);

const WindowState = struct {
    running: bool,
};

fn window_proc(hwnd: win32.HWND, message: win32.UINT, w_param: win32.WPARAM, l_param: win32.LPARAM) callconv(.c) win32.LRESULT {
    switch (message) {
        win32.WM_CREATE => {
            const state: ?*win32.CREATESTRUCTA = @ptrFromInt(@as(usize, @intCast(l_param)));
            if (state) |s| {
                _ = win32.SetWindowLongPtrA(hwnd, win32.GWLP_USERDATA, @intCast(@intFromPtr(s.lpCreateParams)));
            }

            return 0;
        },
        win32.WM_CLOSE => {
            const state: ?*WindowState = @ptrFromInt(@as(usize, @intCast(win32.GetWindowLongPtrA(hwnd, win32.GWLP_USERDATA))));
            if (state) |s| {
                s.running = false;
            }

            _ = win32.DestroyWindow(hwnd);
            return 0;
        },
        win32.WM_DESTROY => {
            return 0;
        },
        else => return win32.DefWindowProcA(hwnd, message, w_param, l_param),
    }
}

pub fn main(init: std.process.Init) !void {
    _ = init;

    const h_instance = win32.GetModuleHandleA(null);

    const class_name = "Sample Window Class";
    var wc: win32.WNDCLASS = .{};
    wc.lpfnWndProc = window_proc;
    wc.hInstance = h_instance;
    wc.lpszClassName = class_name;
    wc.hCursor = win32.LoadCursorA(null, @ptrFromInt(IDC_ARROW));

    _ = win32.RegisterClassA(&wc);

    var state = WindowState {
        .running = true,  
    };

    const hwnd: win32.HWND = win32.CreateWindowExA(
        0,
        class_name,
        "but, it works!",
        win32.WS_OVERLAPPEDWINDOW,

        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        1280,
        720,
        null,
        null,
        h_instance,
        &state,
    );

    if (hwnd == null) {
        return;
    }

    const screen_width = win32.GetSystemMetrics(win32.SM_CXSCREEN);
    const screen_height = win32.GetSystemMetrics(win32.SM_CYSCREEN);

    _ = win32.SetWindowPos(
        hwnd,
        null,
        @divFloor(screen_width - 1280, 2),
        @divFloor(screen_height - 720, 2),
        0, 
        0,
        win32.SWP_NOZORDER | win32.SWP_NOSIZE
    );

    _ = win32.ShowWindow(hwnd, win32.SW_NORMAL);

    var message: win32.MSG = .{};
    var found_message: bool = false;
    while (state.running) {
        found_message = win32.PeekMessageA(&message, null, 0, 0, win32.PM_REMOVE) != 0;

        while (found_message) {
            _ = win32.TranslateMessage(&message); 
            _ = win32.DispatchMessageA(&message);

            found_message = win32.PeekMessageA(&message, null, 0, 0, win32.PM_REMOVE) != 0;
        }
    }
}
