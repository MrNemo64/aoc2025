const std = @import("std");

pub fn addDay(comptime name: []const u8, b: *std.Build, target: *const std.Build.ResolvedTarget, optimize: *const std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "aoc2025-" ++ name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/" ++ name ++ ".zig"),
            .target = target.*,
            .optimize = optimize.*,
            .imports = &.{},
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run-" ++ name, "Run the " ++ name);

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    addDay("day1", b, &target, &optimize);
    addDay("day2", b, &target, &optimize);
    addDay("day3", b, &target, &optimize);
}
