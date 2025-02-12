const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    var args = std.process.argsWithAllocator(allocator) catch |err| {
        try stdout.print("Unexpected error: {}", .{err});
        return;
    };
    defer args.deinit();

    // The first argument is always the executed command, is safe to ignore.
    _ = args.next();

    const command = args.next();
    if (command == null) {
        try stdout.print(
            \\You need to provide a command.
            \\Use the 'help' command for more information...
        ++ "\n", .{});

        return;
    }

    // Convert iterator to slice.
    var args_list = std.ArrayList([]const u8).init(allocator);
    defer args_list.deinit();

    while (args.next()) |arg| {
        try args_list.append(arg);
    }

    const cmd_args = args_list.items;

    if (std.mem.eql(u8, command.?, "help")) {
        cmdHelp(cmd_args);
    } else if (std.mem.eql(u8, command.?, "xxd")) {
        @import("CmdXxd.zig").run(cmd_args);
    } else {
        try stdout.print(
            \\Command not found: '{s}'.
            \\Use the 'help' command for more information...
        ++ "\n", .{command.?});
    }
}

fn cmdHelp(_: []const []const u8) void {
    std.debug.print("I'm here.\n", .{});
}
