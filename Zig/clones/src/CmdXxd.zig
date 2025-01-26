const std = @import("std");

pub fn run(args: []const []const u8) void {
    const stdout = std.io.getStdOut().writer();
    const filename = args[args.len - 1];

    const file = std.fs.cwd().openFile(filename, .{ .mode = std.fs.File.OpenMode.read_only }) catch |err| {
        stdout.print("Unexpected error: {}\n", .{err}) catch {};
        return;
    };
    defer file.close();

    const metadata = file.metadata() catch |err| {
        stdout.print("Unexpected error: {}\n", .{err}) catch {};
        return;
    };

    std.debug.print(
        \\Path: {s}
        \\Size: {}
    ++ "\n", .{ filename, metadata.size() });
}
