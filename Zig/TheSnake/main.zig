const std = @import("std");

const linux = std.os.linux;

const App = struct {
    const Direction = enum { up, down, left, right };
    const Snake = struct {
        var x: u8 = 6;
        var y: u8 = 6;
        var direction: Direction = .down;
    };
    const Board = struct {
        var maxX: u16 = 0;
        var maxY: u16 = 0;
    };

    var ticks: u64 = 0;

    fn update() bool {
        switch (readChar()) {
            'q' => return true,

            '\x1b' => switch (readChar()) {
                '[' => switch (readChar()) {
                    'A' => Snake.direction = .up,
                    'B' => Snake.direction = .down,
                    'C' => Snake.direction = .right,
                    'D' => Snake.direction = .left,
                    else => {},
                },
                else => {},
            },

            else => {},
        }

        if (ticks % 20 == 0) {
            switch (Snake.direction) {
                .up => if (Snake.y > 1) {
                    Snake.y -= 1;
                },
                .down => if (Snake.y < Board.maxY - 2) {
                    Snake.y += 1;
                },
                .left => if (Snake.x > 2) {
                    Snake.x -= 2;
                },
                .right => if (Snake.x < Board.maxX - 3) {
                    Snake.x += 2;
                },
            }
        }

        ticks += 1;

        return false;
    }

    // Caller must free returned slice.
    fn draw(allocator: std.mem.Allocator) ![]u8 {
        var output = try allocator.alloc(u8, 0);

        var i: u16 = 0;
        while (i <= Board.maxX) : (i += 1) {
            var j: u16 = 0;
            while (j <= Board.maxY) : (j += 1) {
                if (((i != 0) and (i != (Board.maxX))) and ((j != 0) and (j != Board.maxY))) {
                    continue;
                }

                try setPos(allocator, &output, i, j);
                const block = "\x1b[40m  \x1b[49m";
                output = try allocator.realloc(output, output.len + block.len);
                std.mem.copyForwards(u8, output[output.len - block.len ..], block);
            }
        }

        try setPos(allocator, &output, Snake.x, Snake.y);
        const hello = "\x1b[7m··\x1b[27m";
        output = try allocator.realloc(output, output.len + hello.len);
        std.mem.copyForwards(u8, output[output.len - hello.len ..], hello);

        return output;
    }

    // Caller must free memory.
    fn setPos(allocator: std.mem.Allocator, base: *[]u8, x: u16, y: u16) !void {
        const n = 3;

        const home = "\x1b[H";

        var output = base.*;

        output = try allocator.realloc(output, output.len + home.len);
        _ = try std.fmt.bufPrint(output[output.len - home.len ..], home, .{});

        if (x > 0) {
            const moveRightStart = "\x1b[";
            const moveRightEnd = "C";

            output = try allocator.realloc(output, output.len + moveRightStart.len + n + moveRightEnd.len);
            const printed = try std.fmt.bufPrint(output[output.len - moveRightStart.len - n - moveRightEnd.len ..], moveRightStart ++ "{}" ++ moveRightEnd, .{x});
            output = try allocator.realloc(output, output.len - n + printed.len - moveRightStart.len - moveRightEnd.len);
        }

        if (y > 0) {
            const moveDownStart = "\x1b[";
            const moveDownEnd = "B";

            output = try allocator.realloc(output, output.len + moveDownStart.len + n + moveDownEnd.len);
            const printed = try std.fmt.bufPrint(output[output.len - moveDownStart.len - n - moveDownEnd.len ..], moveDownStart ++ "{}" ++ moveDownEnd, .{y});
            output = try allocator.realloc(output, output.len - n + printed.len - moveDownStart.len - moveDownEnd.len);
        }

        base.* = output;
    }
};

test "setPos behavior" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;

    var output = try allocator.alloc(u8, 0);
    try App.setPos(allocator, &output, 37, 42);
    try expect(std.mem.eql(u8, output, "\x1b[H\x1b[37C\x1b[42B"));
    allocator.free(output);

    output = try allocator.alloc(u8, 0);
    try App.setPos(allocator, &output, 0, 0);
    try expect(std.mem.eql(u8, output, "\x1b[H"));
    allocator.free(output);

    output = try allocator.alloc(u8, 0);
    try App.setPos(allocator, &output, 1, 0);
    try expect(std.mem.eql(u8, output, "\x1b[H\x1b[1C"));
    allocator.free(output);

    output = try allocator.alloc(u8, 0);
    try App.setPos(allocator, &output, 0, 1);
    try expect(std.mem.eql(u8, output, "\x1b[H\x1b[1B"));
    allocator.free(output);
}

const stdinFd = 0;

fn enableRawMode() void {
    var termios: linux.termios = undefined;
    _ = linux.tcgetattr(stdinFd, &termios);
    termios.lflag.ECHO = false;
    termios.lflag.ICANON = false;
    termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    termios.cc[@intFromEnum(linux.V.TIME)] = 0;
    _ = linux.tcsetattr(stdinFd, linux.TCSA.DRAIN, &termios);
}

fn getWinSize() struct { x: u16, y: u16 } {
    var winsize: std.posix.winsize = undefined;
    _ = linux.ioctl(stdinFd, linux.T.IOCGWINSZ, @intFromPtr(&winsize));

    return .{ .x = winsize.col, .y = winsize.row };
}

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

fn readChar() u8 {
    var buf: [1]u8 = undefined;
    _ = stdin.read(&buf) catch {
        std.debug.panic("Error reading character!", .{});
    };

    return buf[0];
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    enableRawMode();

    try stdout.print("\x1b[?1049h", .{}); // Enable alternate buffer.
    defer stdout.print("\x1b[?1049l", .{}) catch {}; // Disable alternate buffer.

    try stdout.print("\x1b[?25l", .{}); // Make the cursor invisible.

    const startTimestamp = std.time.milliTimestamp();

    const size = getWinSize();
    if (size.x % 2 != 0) {
        App.Board.maxX = size.x - 2 - 1;
    } else {
        App.Board.maxX = size.x - 2;
    }
    App.Board.maxY = size.y;

    var shouldExit = false;
    while (!shouldExit) {
        shouldExit = App.update();
        const text = try App.draw(allocator);
        try stdout.print("\x1b[H\x1b[2J{s}", .{text});
        allocator.free(text);

        const waitTime = @abs(@rem(std.time.milliTimestamp() - startTimestamp, 16));
        std.Thread.sleep(waitTime * 1000000);
    }
}
