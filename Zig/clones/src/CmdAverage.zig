const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;

const stdout = std.io.getStdOut().writer();

pub fn run(args: [][]const u8) void {
    if (args.len == 0) {
        stdout.print("You need to provide at least one argument!\n", .{}) catch {};
        return;
    }

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var numbers = std.ArrayList(u128).init(allocator);
    defer numbers.deinit();

    for (args) |number| {
        numbers.append(fmt.parseUnsigned(u128, number, 10) catch {
            stdout.print("Invalid positive integer: {s}\n", .{number}) catch {};
            return;
        }) catch |err| {
            stdout.print("Error allocating memory: {}\n", .{err}) catch {};
        };
    }

    var average: u128 = 0;
    var dynamicAverage: u128 = 0;
    var dynamicAverageCount: u128 = 0;

    for (numbers.items, 1..) |number, index| {
        average += number;
        dynamicAverage += number * index;
        dynamicAverageCount += index;
    }

    average /= numbers.items.len;
    dynamicAverage /= dynamicAverageCount;

    stdout.print(
        \\Average: {[average]}
        \\Dynamic Average: {[dynamicAverage]}
    ++ "\n", .{ .average = average, .dynamicAverage = dynamicAverage }) catch {};
}
