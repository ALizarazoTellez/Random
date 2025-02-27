// Copyright (C) 2025, Anderson Lizarazo Tellez.

const std = @import("std");

const zdt = @import("zdt");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // TODO(ALizarazoTellez): Don't hardcode timezone.
    var currentTz = try zdt.Timezone.fromTzdata("America/Bogota", allocator);
    defer currentTz.deinit();

    try stdout.print("Hello {any}\n", .{zdt.Datetime.now(.{ .tz = &currentTz })});
}
