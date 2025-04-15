const std = @import("std");

const testing = std.testing;
const mem = std.mem;

pub const String = struct {
    allocator: mem.Allocator,
    s: []u8,

    pub fn init(allocator: mem.Allocator) !String {
        const s = try allocator.alloc(u8, 0);
        return String{
            .allocator = allocator,
            .s = s,
        };
    }

    pub fn deinit(self: *String) void {
        self.allocator.free(self.s);
        self.s = undefined;
    }

    pub fn concat(self: *String, s: []const u8) !void {
        self.s = try self.allocator.realloc(self.s, self.s.len + s.len);
        mem.copyForwards(u8, self.s[self.s.len - s.len ..], s);
    }

    pub fn concatU16(self: *String, u: u16) !void {
        self.s = try self.allocator.realloc(self.s, self.s.len + 5);
        const s = try std.fmt.bufPrint(self.s[self.s.len - 5 ..], "{}", .{u});
        self.s = try self.allocator.realloc(self.s, self.s.len - (5 - s.len));
    }

    pub fn repeat(self: *String, s: []const u8, times: u16) !void {
        var i: u16 = 0;
        while (i < times) : (i += 1) {
            try self.concat(s);
        }
    }
};

test "basic" {
    var s: String = try .init(testing.allocator);
    defer s.deinit();

    try testing.expect(mem.eql(u8, "", s.s));

    try s.concat("one");
    try testing.expect(mem.eql(u8, "one", s.s));
}

test "self" {
    var a: String = try .init(testing.allocator);
    defer a.deinit();

    var b: String = try .init(testing.allocator);
    defer b.deinit();

    try a.concat("a");
    try b.concat("b");

    try a.concat(b.s);
    try testing.expect(mem.eql(u8, "ab", a.s));
}

test "number" {
    var s: String = try .init(testing.allocator);
    defer s.deinit();

    try s.concatU16(12345);
    try testing.expect(mem.eql(u8, "12345", s.s));
}

test "repeat" {
    var s: String = try .init(testing.allocator);
    defer s.deinit();

    try s.repeat("Zig", 3);
    try testing.expect(mem.eql(u8, "ZigZigZig", s.s));
}
