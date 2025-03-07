const std = @import("std");

pub fn run(args: []const []const u8) void {
    const stdout = std.io.getStdOut().writer();

    if (args.len != 1) {
        stdout.print(
            \\This command needs exactly one argument!
            \\The argument is the number of iterations.
        ++ "\n", .{}) catch {};
        return;
    }

    const iterations = std.fmt.parseUnsigned(u128, args[0], 10) catch {
        stdout.print("The argument must be a positive integer.\n", .{}) catch {};
        return;
    };

    var defaultPrng = std.rand.DefaultPrng.init(0);
    const random = defaultPrng.random();

    configureTerminal();
    defer restoreTerminal();

    _ = std.os.linux.sigaction(std.os.linux.SIG.INT, &std.os.linux.Sigaction{
        .handler = .{ .handler = &sigintHandler },
        .flags = 0,
        .mask = std.os.linux.empty_sigset,
    }, null);

    var total: u128 = 0;
    var totalHeads: u128 = 0;
    var totalTails: u128 = 0;
    while (total < iterations) : (total += 1) {
        const isHeads = random.boolean();

        if (isHeads) {
            totalHeads += 1;
        } else {
            totalTails += 1;
        }

        const percentHeads = @as(f128, @floatFromInt(totalHeads)) / @as(f128, @floatFromInt(total + 1)) * 100;
        const percentTails = @as(f128, @floatFromInt(totalTails)) / @as(f128, @floatFromInt(total + 1)) * 100;

        const difference = @abs(@as(i128, @intCast(totalHeads)) - @as(i128, @intCast(totalTails)));
        const percentDifference = @as(f128, @floatFromInt(difference)) / @as(f128, @floatFromInt(total + 1)) * 100;

        stdout.print(
            \\Target iterations: {[total]}
            \\Current iterations: {[current]}
            \\
            \\Total heads: {[percentHeads]d:.3}% ({[totalHeads]})
            \\Total tails: {[percentTails]d:.3}% ({[totalTails]})
            \\
            \\Difference: {[percentDifference]d:.3}% ({[totalDifference]})
        ++ "\n", .{ .total = iterations, .current = total + 1, .percentHeads = percentHeads, .totalHeads = totalHeads, .percentTails = percentTails, .totalTails = totalTails, .percentDifference = percentDifference, .totalDifference = difference }) catch {};

        stdout.writeAll("\x1b[7A") catch {};
    }

    stdout.writeAll("\x1b[7B") catch {};
}

fn sigintHandler(_: i32) callconv(.C) void {
    restoreTerminal();
    const stdout = std.io.getStdOut().writer();
    stdout.print("\nSignal received, exiting...\n", .{}) catch {};
    std.os.linux.exit(0);
}

var termios: std.os.linux.termios = undefined;

fn configureTerminal() void {
    const stdout = std.io.getStdOut();
    stdout.writeAll("\x1b[?25l") catch {};

    _ = std.os.linux.tcgetattr(stdout.handle, &termios);

    var modifiedTermios = termios;
    modifiedTermios.lflag.ECHO = false;
    modifiedTermios.lflag.ICANON = false;
    //modifiedTermios.lflag.ISIG = false;
    modifiedTermios.lflag.IEXTEN = false;
    modifiedTermios.iflag.IXON = false;
    modifiedTermios.iflag.ICRNL = false;
    //modifiedTermios.oflag.OPOST = false;

    _ = std.os.linux.tcsetattr(stdout.handle, std.os.linux.TCSA.FLUSH, &modifiedTermios);
}

fn restoreTerminal() void {
    const stdout = std.io.getStdOut();
    stdout.writeAll("\x1b[?25h") catch {};

    _ = std.os.linux.tcsetattr(stdout.handle, std.os.linux.TCSA.FLUSH, &termios);
}
