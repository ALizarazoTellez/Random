const std = @import("std");

pub fn run(args: []const []const u8) void {
    for (args) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
