pub const c = @import("win32");
pub const IDC_ARROW = @as(c_int, 32512);

pub inline fn LOWORD(n: c_longlong) c_longlong {
    return 0x0000FFFF & n;
}

pub inline fn HIWORD(n: c_longlong) c_longlong {
    return n >> 16;
}