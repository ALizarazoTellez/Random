const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut().writer();

    var args = std.process.argsWithAllocator(allocator) catch |err| {
        stdout.print("Unexpected error: {}", .{err});
    };
    defer args.deinit();

    // The first argument is always the executed command, is safe to ignore.
    _ = args.next();

    const command = args.next();
    if (command == null) {
        try stdout.print(
            \\You need to provide a command.
            \\Use the `help` command for more information.
        ++ "\n", .{});

        return;
    }

    if (std.mem.eql(u8, command.?, "help")) {
        cmdHelp();
    } else if (std.mem.eql(u8, command.?, "xxd")) {
        @import("CmdXxd.zig").run(&[_][]const u8{ "Hi", "Zig" });
    }
}

fn cmdHelp() void {
    std.debug.print("I'm here.\n", .{});
}
