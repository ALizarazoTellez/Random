const std = @import("std");

const linux = std.os.linux;

const term = @import("term.zig");
const ansi = @import("ansi.zig");

const String = @import("string.zig").String;

const App = struct {
    const Direction = enum { up, down, left, right };
    const Coords = struct { x: u16, y: u16 };
    const Snake = struct {
        var bodyArray: [100]Coords = undefined;
        var body: []Coords = undefined;
        var direction: Direction = .right;

        fn init() void {
            @memset(&Snake.bodyArray, .{ .x = 0, .y = 0 });
            Snake.body = Snake.bodyArray[0..1];
            Snake.head().x = Board.maxX / 2 - 4;
            Snake.head().y = Board.maxY / 2;
        }

        fn head() *Coords {
            return &Snake.body[0];
        }

        fn increase() void {
            Snake.body = Snake.bodyArray[0 .. Snake.body.len + 1];
            Snake.move();
        }

        fn move() void {
            var end = Snake.body.len - 1;
            while (end > 0) {
                Snake.body[end] = Snake.body[end - 1];
                end -= 1;
            }

            switch (Snake.direction) {
                .up => if (Snake.head().y > 1) {
                    Snake.head().y -= 1;
                },
                .down => if (Snake.head().y < Board.maxY - 2) {
                    Snake.head().y += 1;
                },
                .left => if (Snake.head().x > 2) {
                    Snake.head().x -= 2;
                },
                .right => if (Snake.head().x < Board.maxX - 4) {
                    Snake.head().x += 2;
                },
            }
        }
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

        if (ticks % 20 == 0 and ticks % 40 != 0) {
            Snake.move();
        }
        if (ticks % 40 == 0) {
            Snake.increase();
        }

        ticks += 1;

        return false;
    }

    fn draw(output: *String) !void {
        try output.concat(ansi.blackBackground);
        try output.repeat(" ", Board.maxX);
        var i: u16 = 1;
        while (i <= Board.maxY - 2) : (i += 1) {
            try setPos(output, 0, i);
            try output.concat("  ");
            try setPos(output, Board.maxX - 2, i);
            try output.concat("  ");
        }
        try setPos(output, 0, Board.maxY);
        try output.repeat(" ", Board.maxX);
        try output.concat(ansi.defaultBackground);

        try setPos(output, Snake.head().x, Snake.head().y);
        const hello = ansi.inverseMode ++ "··" ++ ansi.noInverseMode;
        try output.concat(hello);

        for (Snake.body[1..], 0..) |body, index| {
            try setPos(output, body.x, body.y);
            var texture = "  ";
            if (index % 4 == 1) {
                texture = "--";
            } else if (index % 2 == 1) {
                texture = "||";
            }
            try output.concat(ansi.inverseMode);
            try output.concat(texture);
            try output.concat(ansi.noInverseMode);
        }
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
        App.Board.maxX = size.cols - 1;
    } else {
        App.Board.maxX = size.cols;
    }
    App.Board.maxY = size.rows;

    App.Snake.init();

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
