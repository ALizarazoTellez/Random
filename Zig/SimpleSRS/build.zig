// Copyright (C) 2025, Anderson Lizarazo Tellez.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "SimpleSRS",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
    });
    b.installArtifact(exe);

    const zdt = b.dependency("zdt", .{});
    exe.root_module.addImport("zdt", zdt.module("zdt"));
    exe.linkLibrary(zdt.artifact("zdt"));

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
