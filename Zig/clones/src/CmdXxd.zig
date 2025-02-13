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

    const maxLineBytes = 16;
    const reader = file.reader();

    var lineBytes: u5 = 0;
    var index: u32 = 0;

    while (true) {
        if (lineBytes == 0) {
            stdout.print("{x:0>8}: ", .{index}) catch {};
        }

        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => {
                stdout.print("Unexpected error: {}\n", .{err}) catch {};
                return;
            },
        };

        stdout.print("{x:0>2}", .{byte}) catch {};

        lineBytes += 1;
        if (lineBytes == maxLineBytes) {
            stdout.print("\n", .{}) catch {};
            lineBytes = 0;
        } else if (@mod(lineBytes, 2) == 0) {
            stdout.print(" ", .{}) catch {};
        }

        index += 1;
    }

    stdout.print("\n", .{}) catch {};
}
