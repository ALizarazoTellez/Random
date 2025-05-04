const std = @import("std");

pub const ESC = "\x1b";

pub const CSI = struct {
    pub const moveHome = 'H';
    pub const moveLeft = 'D';

    pub const eraseScreen = 'J';
    pub const colorMode = 'm';
    pub const COLOR_MODE = struct {
        pub const inverse = 7;
        pub const noInverse = 27;

        pub const defaultBackground = 49;
        pub const blackBackground = 40;

        pub const brightBlackBackground = 90;
    };
};

// Private sequences.
pub const makeCursorInvisible = ESC ++ "[?25l";
pub const makeCursorVisible = ESC ++ "[?25h";
pub const enableAlternativeBuffer = ESC ++ "[?1049h";
pub const disableAlternativeBuffer = ESC ++ "[?1049l";

pub const Encoder = struct {
    output: std.io.AnyWriter,

    pub fn init(writer: std.io.AnyWriter) Encoder {
        return Encoder{ .output = writer };
    }

    pub fn csi(self: Encoder, command: u8, args: anytype) !void {
        const fields_info = @typeInfo(@TypeOf(args)).@"struct".fields;

        _ = try self.output.write(ESC ++ "[");

        comptime var i = 0;
        inline while (i < fields_info.len) : (i += 1) {
            const field = @field(args, fields_info[i].name);
            switch (@typeInfo(@TypeOf(field))) {
                .comptime_int => _ = try self.output.print("{};", .{field}),
                .pointer => _ = try self.output.write(field ++ ";"),
                else => unreachable,
            }
        }

        _ = try self.output.write(&.{command});
    }
};

test "CSI" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const enc: Encoder = .init(list.writer().any());

    try enc.csi('a', .{ "b", "c" });
    try std.testing.expect(std.mem.eql(u8, list.items, ESC ++ "[b;c;a"));

    list.clearAndFree();

    try enc.csi('d', .{});
    try std.testing.expect(std.mem.eql(u8, list.items, ESC ++ "[d"));

    list.clearAndFree();

    try enc.csi('e', .{ 1, 2 });
    try std.testing.expect(std.mem.eql(u8, list.items, ESC ++ "[1;2;e"));

    list.clearAndFree();

    try enc.csi('f', .{ "gh", 3 });
    try std.testing.expect(std.mem.eql(u8, list.items, ESC ++ "[gh;3;f"));
}
