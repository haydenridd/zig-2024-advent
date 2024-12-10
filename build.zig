const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Helper utilities module
    const helpers_mod = b.addModule("helpers", .{ .root_source_file = b.path("helpers/helpers.zig") });
    const helpers_test = b.addTest(.{
        .root_source_file = b.path("helpers/helpers.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_helpers_test = b.addRunArtifact(helpers_test);

    // Overall testing
    const overall_test_step = b.step("test", "Run unit tests");
    overall_test_step.dependOn(&run_helpers_test.step);

    // Overall run step
    const overall_run_step = b.step("run", "Run all days");

    // Building each day individually
    const max_day = 9;
    inline for (1..max_day + 1) |day| {
        const day_name = std.fmt.comptimePrint("day{}", .{day});
        const day_path = b.path("src/" ++ day_name ++ ".zig");
        const exe = b.addExecutable(.{
            .name = day_name,
            .root_source_file = day_path,
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("helpers", helpers_mod);

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run_" ++ day_name, "Run " ++ day_name);
        run_step.dependOn(&run_cmd.step);
        overall_run_step.dependOn(run_step);
        const exe_unit_tests = b.addTest(.{
            .root_source_file = day_path,
            .target = target,
            .optimize = optimize,
        });
        exe_unit_tests.root_module.addImport("helpers", helpers_mod);
        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const test_step = b.step("test_" ++ day_name, "Run unit tests for - " ++ day_name);
        test_step.dependOn(&run_exe_unit_tests.step);
        overall_test_step.dependOn(test_step);
    }
}
