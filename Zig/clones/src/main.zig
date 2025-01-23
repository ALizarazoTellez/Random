const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    var args = std.process.argsWithAllocator(allocator) catch |err| {
        stdout.print("Unexpected error: {}", .{err});
    };
    defer args.deinit();

    while (args.next()) |arg| {
        try stdout.print("Arg: {s}\n", .{arg});
    }
}
