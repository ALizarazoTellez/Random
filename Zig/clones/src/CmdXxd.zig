const std = @import("std");

pub fn run(args: []const []const u8) void {
    const stdout = std.io.getStdOut().writer();

    if (args.len != 1) {
        stdout.print(
            \\This command needs exactly one argument!
            \\The argument is the path to a binary file.
        ++ "\n", .{}) catch {};
        return;
    }

    // The last argument must be the binary file.
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

    const reader = file.reader();
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => {
                stdout.print("Unexpected error: {}\n", .{err}) catch {};
                return;
            },
        };

        stdout.print("{x}", .{byte}) catch {};
    }

    stdout.print("\n", .{}) catch {};
}
