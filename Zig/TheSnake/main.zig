const std = @import("std");

const term = @import("term.zig");
const ansi = @import("ansi.zig");

const Game = @import("game.zig").Game;
const String = @import("string.zig").String;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    term.setRawMode(true);
    defer term.setRawMode(false);

    try stdout.print(ansi.enableAlternativeBuffer, .{});
    defer stdout.print(ansi.disableAlternativeBuffer, .{}) catch {};

    try stdout.print(ansi.makeCursorInvisible, .{});
    defer stdout.print(ansi.makeCursorVisible, .{}) catch {};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var prng = std.Random.DefaultPrng.init(0);

    var game = try Game.init(gpa.allocator(), prng.random());
    try game.mainloop();
}
