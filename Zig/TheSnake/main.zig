const std = @import("std");

const linux = std.os.linux;

const term = @import("term.zig");
const ansi = @import("ansi.zig");

const String = @import("string.zig").String;

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
        switch (term.readChar()) {
            'q' => return true,

            '\x1b' => switch (term.readChar()) {
                '[' => switch (term.readChar()) {
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

    fn draw(output: *String) !void {
        var i: u16 = 0;
        while (i <= Board.maxX) : (i += 1) {
            var j: u16 = 0;
            while (j <= Board.maxY) : (j += 1) {
                if (((i != 0) and (i != (Board.maxX))) and ((j != 0) and (j != Board.maxY))) {
                    continue;
                }

                try setPos(output, i, j);
                const block = ansi.blackBackground ++ "  " ++ ansi.defaultBackground;
                try output.concat(block);
            }
        }

        try setPos(output, Snake.x, Snake.y);
        const hello = ansi.inverseMode ++ "··" ++ ansi.noInverseMode;
        try output.concat(hello);
    }

    fn setPos(output: *String, x: u16, y: u16) !void {
        try output.concat(ansi.positionHome);

        if (x > 0) {
            const moveRightStart = "\x1b[";
            const moveRightEnd = "C";

            try output.concat(moveRightStart);
            try output.concatU16(x);
            try output.concat(moveRightEnd);
        }

        if (y > 0) {
            const moveDownStart = "\x1b[";
            const moveDownEnd = "B";

            try output.concat(moveDownStart);
            try output.concatU16(y);
            try output.concat(moveDownEnd);
        }
    }
};

test "setPos behavior" {
    const expect = std.testing.expect;

    var output: String = try .init(std.testing.allocator);
    try App.setPos(&output, 37, 42);
    try expect(std.mem.eql(u8, output.s, "\x1b[H\x1b[37C\x1b[42B"));
    output.deinit();

    output = try .init(std.testing.allocator);
    try App.setPos(&output, 0, 0);
    try expect(std.mem.eql(u8, output.s, "\x1b[H"));
    output.deinit();

    output = try .init(std.testing.allocator);
    try App.setPos(&output, 1, 0);
    try expect(std.mem.eql(u8, output.s, "\x1b[H\x1b[1C"));
    output.deinit();

    output = try .init(std.testing.allocator);
    try App.setPos(&output, 0, 1);
    try expect(std.mem.eql(u8, output.s, "\x1b[H\x1b[1B"));
    output.deinit();
}

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    term.setRawMode(true);
    defer term.setRawMode(false);

    try stdout.print(ansi.enableAlternativeBuffer, .{});
    defer stdout.print(ansi.disableAlternativeBuffer, .{}) catch {};

    try stdout.print(ansi.makeCursorInvisible, .{});
    defer stdout.print(ansi.makeCursorVisible, .{}) catch {};

    const startTimestamp = std.time.milliTimestamp();

    const size = term.getSize();

    if (size.cols % 2 != 0) {
        App.Board.maxX = size.cols - 2 - 1;
    } else {
        App.Board.maxX = size.cols - 2;
    }
    App.Board.maxY = size.rows;

    var shouldExit = false;
    while (!shouldExit) {
        shouldExit = App.update();

        var string: String = try .init(allocator);
        try App.draw(&string);
        try stdout.print(ansi.positionHome ++ ansi.eraseEntireScreen ++ "{s}", .{string.s});
        string.deinit();

        const waitTime = @abs(@rem(std.time.milliTimestamp() - startTimestamp, 16));
        std.Thread.sleep(waitTime * 1000000);
    }
}
