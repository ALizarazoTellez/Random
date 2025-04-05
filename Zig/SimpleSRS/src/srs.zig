const std = @import("std");

const zdt = @import("zdt");

pub const Day = struct {
    tz: *zdt.Timezone,
    unix: i128,

    const resolution = zdt.Duration.Resolution.second;

    pub fn today(tz: *zdt.Timezone) !Day {
        return .{
            .tz = tz,
            .unix = (try (try zdt.Datetime.now(.{ .tz = tz })).floorTo(.day)).toUnix(resolution),
        };
    }

    pub fn formated(self: Day, alloc: std.mem.Allocator) ![]const u8 {
        const dt = zdt.Datetime.fromUnix(self.unix, Day.resolution, .{ .tz = self.tz });

        var buf = std.ArrayList(u8).init(alloc);
        //defer buf.deinit();

        try (try dt).toString("Day is %d\n", buf.writer());

        return buf.items;
    }
};

const Item = struct {
    title: []const u8,
    description: []const u8,

    interval: u9,
    lastDay: Day,

    fn init(title: []const u8) Item {
        return .{
            .title = title,
        };
    }
};
