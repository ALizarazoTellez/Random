// Copyright (C) 2025, Anderson Lizarazo Tellez.

const std = @import("std");

const zdt = @import("zdt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try stdout.print("Hello {any}\n", .{zdt.Datetime.now(null)});
}
