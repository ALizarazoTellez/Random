const std = @import("std");

const term = @import("term.zig");
const ansi = @import("ansi.zig");

const TICK_DURATION_NS = (1000 / 60) * 1e6;

const String = @import("string.zig").String;

const Coord = struct {
    x: u16,
    y: u16,

    fn equal(self: Coord, other: Coord) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Direction = enum { up, down, left, right };

const Snake = struct {
    cols: u16,
    rows: u16,

    bodyArray: [100]Coord,
    bodyLen: usize,

    direction: Direction = .right,

    fn init(cols: u16, rows: u16) Snake {
        var bodyArray: [100]Coord = undefined;
        @memset(&bodyArray, .{ .x = 0, .y = 0 });

        var snake = Snake{
            .cols = cols,
            .rows = rows,
            .bodyArray = bodyArray,
            .bodyLen = 1,
        };

        snake.head().x = cols / 2;
        snake.head().y = rows / 2;

        return snake;
    }

    fn head(self: *Snake) *Coord {
        return &self.bodyArray[0];
    }

    fn body(self: *Snake) []Coord {
        return self.bodyArray[0..self.bodyLen];
    }

    fn increase(self: *Snake) void {
        if (self.bodyLen < self.bodyArray.len) {
            self.bodyLen += 1;
        }
    }

    fn move(self: *Snake) void {
        var end = self.bodyLen - 1;
        while (end > 0) {
            self.body()[end] = self.body()[end - 1];
            end -= 1;
        }

        switch (self.direction) {
            .up => if (self.head().y > 1) {
                self.head().y -= 1;
            },
            .down => if (self.head().y < self.rows) {
                self.head().y += 1;
            },
            .left => if (self.head().x > 1) {
                self.head().x -= 1;
            },
            .right => if (self.head().x < self.cols) {
                self.head().x += 1;
            },
        }
    }
};

pub const Game = struct {
    allocator: std.mem.Allocator,

    raw_rows: u16,
    raw_cols: u16,

    rows: u16,
    cols: u16,

    random: std.Random,

    snake: Snake,
    apple: Coord,

    buffer: String,

    ticks: u64 = 0,
    points: u64 = 0,
    is_game_over: bool = true,

    pub fn init(allocator: std.mem.Allocator, random: std.Random) !Game {
        var size = term.getSize();
        if (size.cols % 2 != 0) {
            size.cols -= 1;
        }

        var game = Game{
            .allocator = allocator,

            .raw_cols = size.cols,
            .raw_rows = size.rows,

            // Margin uses one cell at both sides (two in total).
            .cols = size.cols / 2 - 2,
            .rows = size.rows - 2,

            .random = random,

            .snake = undefined,
            .apple = undefined,

            .buffer = try .init(allocator),
        };

        game.snake = .init(game.cols, game.rows);
        game.apple = game.randomFreeCoord();

        return game;
    }

    pub fn mainloop(self: *Game) !void {
        const stdout = std.io.getStdOut().writer();

        while (true) {
            const start_tick_time: u64 = @intCast(std.time.nanoTimestamp());

            self.ticks += 1;
            self.update() catch {
                break;
            };

            const update_tick_time: u64 = @intCast(std.time.nanoTimestamp());

            if (update_tick_time > start_tick_time + @as(u64, TICK_DURATION_NS)) {
                std.debug.print("Skiped frame.\n", .{});
                continue;
            }

            self.buffer = try .init(self.allocator);

            const enc: ansi.Encoder = .init(self.buffer.writer());
            try enc.csi(ansi.CSI.moveHome, .{});
            try enc.csi(ansi.CSI.eraseScreen, .{2});

            try self.draw();
            try stdout.print("{s}", .{self.buffer.s});

            self.buffer.deinit();

            const draw_tick_time: u64 = @intCast(std.time.nanoTimestamp());

            // TODO: Render in `draw`.
            try stdout.print("\x1b[H\x1b[3C UPu: {: >5}us - FPu: {: >5}us - FPS: {: >5} ", .{ (update_tick_time - start_tick_time) / @as(u64, 1e3), (draw_tick_time - update_tick_time) / @as(u64, 1e3), @as(u64, 60 * 1e6) / (draw_tick_time - start_tick_time) });

            if (draw_tick_time < start_tick_time + @as(u64, TICK_DURATION_NS)) {
                std.Thread.sleep(start_tick_time + @as(u64, TICK_DURATION_NS) - draw_tick_time);
            }
        }
    }

    fn update(self: *Game) !void {
        input: switch (term.readChar()) {
            'q' => return error.GameFinished,

            '\n' => {
                if (!self.is_game_over) {
                    break :input;
                }

                self.is_game_over = false;
                self.points = 0;
                self.snake = Snake.init(self.cols, self.rows);
                self.apple = self.randomFreeCoord();
            },

            '\x1b' => switch (term.readChar()) {
                '[' => switch (term.readChar()) {
                    'A' => self.snake.direction = .up,
                    'B' => self.snake.direction = .down,
                    'C' => self.snake.direction = .right,
                    'D' => self.snake.direction = .left,
                    else => {},
                },
                else => {},
            },

            else => {},
        }

        if (self.is_game_over) {
            return;
        }

        for (self.snake.body()[1..]) |body| {
            if (self.snake.head().x == body.x and self.snake.head().y == body.y) {
                self.is_game_over = true;
                break;
            }
        }

        if (self.snake.head().equal(self.apple)) {
            self.snake.increase();
            self.snake.move();
            self.apple = self.randomFreeCoord();
            self.points += 1;
        }

        if (self.ticks % 10 == 0) {
            self.snake.move();
        }
    }

    fn randomFreeCoord(self: *Game) Coord {
        var coord = self.randomCoord();

        var i: u64 = 0;
        while (i < self.snake.bodyLen) {
            if (coord.equal(self.snake.body()[i]) or coord.x == 0 or coord.y == 0) {
                coord = self.randomCoord();
                i = 0;
            } else {
                i += 1;
            }
        }

        return coord;
    }

    fn randomCoord(self: Game) Coord {
        return .{
            .x = self.random.uintLessThan(u16, self.cols),
            .y = self.random.uintLessThan(u16, self.rows),
        };
    }

    fn draw(self: *Game) !void {
        const enc: ansi.Encoder = .init(self.buffer.writer());
        if (self.is_game_over) {
            try self.drawMenu();
            return;
        }

        // Frame.
        try enc.csi(ansi.CSI.colorMode, .{ 48, 5, 235 });
        try self.buffer.repeat(" ", self.raw_cols);

        var i: u16 = 1;
        while (i <= self.raw_rows - 2) : (i += 1) {
            try self.buffer.concat("\r\n  ");
        }

        i = 1;
        try self.setPos(Coord{ .x = self.raw_cols - 2, .y = 0 });
        while (i <= self.raw_rows - 2) : (i += 1) {
            try self.buffer.concat("\n  ");
            try enc.csi(ansi.CSI.moveLeft, .{2});
        }

        try self.buffer.concat("\r\n");
        try self.buffer.repeat(" ", self.raw_cols);
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.defaultBackground});

        // Snake head.
        try self.setPos(Coord{ .x = self.snake.head().x * 2, .y = self.snake.head().y });
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.inverse});
        try self.buffer.concat("··");
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.noInverse});

        // Snake body.
        for (self.snake.body()[1..], 0..) |body, index| {
            try self.setPos(Coord{ .x = body.x * 2, .y = body.y });
            var texture = "  ";
            if (index % 4 == 1) {
                texture = "--";
            } else if (index % 2 == 1) {
                texture = "||";
            }
            try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.inverse});
            try self.buffer.concat(texture);
            try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.noInverse});
        }

        // Apple.
        const apple_pos = Coord{ .x = self.apple.x * 2, .y = self.apple.y };
        try self.setPos(apple_pos);
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.inverse});
        try self.buffer.concat("OO");
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.noInverse});
    }

    fn drawMenu(self: *Game) !void {
        const enc: ansi.Encoder = .init(self.buffer.writer());

        try self.buffer.concat("\n\n\r");

        const textGameOver = "Game Over";
        try self.buffer.repeat(" ", self.centerPadding(textGameOver.len));
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.inverse});
        try self.buffer.concat(textGameOver);
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.noInverse});

        try self.buffer.concat("\n\n\r Press 'Q' to quit.");
        try self.buffer.concat("\n\r Press 'Enter' to start a new game.\n\n\r");

        const textTotalPoints = "Total points: ";
        try self.buffer.repeat(" ", self.centerPadding(textTotalPoints.len + 2));
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.inverse});
        try self.buffer.concat(textTotalPoints);
        try self.buffer.concatU16(@truncate(self.points)); // TODO: Make concat generic.
        try enc.csi(ansi.CSI.colorMode, .{ansi.CSI.COLOR_MODE.noInverse});
    }

    fn centerPadding(self: *Game, len: u16) u16 {
        return @truncate(self.raw_cols / 2 - len / 2 + 1);
    }

    fn setPos(self: *Game, coord: Coord) !void {
        const enc: ansi.Encoder = .init(self.buffer.writer());
        try enc.csi(ansi.CSI.moveHome, .{});
        //try self.buffer.concat(ansi.positionHome);

        if (coord.x > 0) {
            const moveRightStart = "\x1b[";
            const moveRightEnd = "C";

            try self.buffer.concat(moveRightStart);
            try self.buffer.concatU16(coord.x);
            try self.buffer.concat(moveRightEnd);
        }

        if (coord.y > 0) {
            const moveDownStart = "\x1b[";
            const moveDownEnd = "B";

            try self.buffer.concat(moveDownStart);
            try self.buffer.concatU16(coord.y);
            try self.buffer.concat(moveDownEnd);
        }
    }
};
