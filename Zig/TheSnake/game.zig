const std = @import("std");

const term = @import("term.zig");
const ansi = @import("ansi.zig");

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

        const start_timestamp = std.time.milliTimestamp();

        while (true) {
            self.update() catch {
                break;
            };

            self.buffer = try .init(self.allocator);
            try self.draw();
            try stdout.print(ansi.positionHome ++ ansi.eraseEntireScreen ++ "{s}", .{self.buffer.s});
            self.buffer.deinit();

            const wait_time = @abs(@rem(std.time.milliTimestamp() - start_timestamp, 16));
            std.Thread.sleep(wait_time * 1000000);
        }
    }

    fn update(self: *Game) !void {
        switch (term.readChar()) {
            'q' => return error.GameFinished,

            '\n' => {
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

        self.ticks += 1;

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

        if (self.ticks % 20 == 0) {
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
        if (self.is_game_over) {
            try self.buffer.concat("Game over\n");
            try self.buffer.concat("Press 'Q' to quit.\n");
            try self.buffer.concat("Press 'Enter' to start a new game.\n");
            try self.buffer.concat("\n\nTotal points: ");
            try self.buffer.concatU16(@truncate(self.points)); // TODO: Make concat generic.
            return;
        }

        // Frame.
        try self.buffer.concat(ansi.blackBackground);
        try self.buffer.repeat(" ", self.raw_cols);
        var i: u16 = 1;
        while (i <= self.raw_rows - 2) : (i += 1) {
            try self.setPos(Coord{ .x = 0, .y = i });
            try self.buffer.concat("  ");
            try self.setPos(Coord{ .x = self.raw_cols - 2, .y = i });
            try self.buffer.concat("  ");
        }
        try self.setPos(Coord{ .x = 0, .y = self.raw_rows });
        try self.buffer.repeat(" ", self.raw_cols);
        try self.buffer.concat(ansi.defaultBackground);

        // Snake head.
        try self.setPos(Coord{ .x = self.snake.head().x * 2, .y = self.snake.head().y });
        const hello = ansi.inverseMode ++ "··" ++ ansi.noInverseMode;
        try self.buffer.concat(hello);

        // Snake body.
        for (self.snake.body()[1..], 0..) |body, index| {
            try self.setPos(Coord{ .x = body.x * 2, .y = body.y });
            var texture = "  ";
            if (index % 4 == 1) {
                texture = "--";
            } else if (index % 2 == 1) {
                texture = "||";
            }
            try self.buffer.concat(ansi.inverseMode);
            try self.buffer.concat(texture);
            try self.buffer.concat(ansi.noInverseMode);
        }

        // Apple.
        const apple_pos = Coord{ .x = self.apple.x * 2, .y = self.apple.y };
        try self.setPos(apple_pos);
        try self.buffer.concat(ansi.inverseMode);
        try self.buffer.concat("OO");
        try self.buffer.concat(ansi.noInverseMode);
    }

    fn setPos(self: *Game, coord: Coord) !void {
        try self.buffer.concat(ansi.positionHome);

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
