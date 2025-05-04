const std = @import("std");

const assert = std.debug.assert;
const linux = std.os.linux;

const stdin = std.io.getStdIn();

/// Returns the terminal size.
pub fn getSize() struct { cols: u16, rows: u16 } {
    var winsize: std.posix.winsize = undefined;
    _ = linux.ioctl(stdin.handle, linux.T.IOCGWINSZ, @intFromPtr(&winsize));

    return .{ .cols = winsize.col, .rows = winsize.row };
}

var termios: ?linux.termios = null;

pub fn setRawMode(enable: bool) void {
    if (enable) {
        assert(termios == null);

        var normalTermios: linux.termios = undefined;
        _ = linux.tcgetattr(stdin.handle, &normalTermios);
        termios = normalTermios;

        normalTermios.lflag.ECHO = false;
        normalTermios.lflag.ICANON = false;
        normalTermios.oflag.OPOST = false;
        normalTermios.cc[@intFromEnum(linux.V.MIN)] = 0;
        normalTermios.cc[@intFromEnum(linux.V.TIME)] = 0;

        _ = linux.tcsetattr(stdin.handle, linux.TCSA.DRAIN, &normalTermios);
    } else {
        assert(termios != null);

        _ = linux.tcsetattr(stdin.handle, linux.TCSA.DRAIN, &termios.?);
        termios = null;
    }
}

pub fn readChar() u8 {
    var buf: [1]u8 = undefined;
    _ = stdin.reader().read(&buf) catch {
        std.debug.panic("Error reading character!", .{});
    };

    return buf[0];
}
