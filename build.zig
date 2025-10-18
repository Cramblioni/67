const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Creating the decoder module
    const mod_dec = b.addModule("dec", .{
        .root_source_file = b.path("src/dec.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Creating the ruleset
    const gen_ruleset = b.addSystemCommand(&.{"python3"});
    gen_ruleset.addFileArg(b.path("src/rulegen.py"));

    // Creating the encoder module
    const mod_enc = b.addModule("enc", .{
        .root_source_file = b.path("src/enc.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "67",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "dec", .module = mod_dec },
                .{ .name = "enc", .module = mod_enc },
            },
        }),
    });

    exe.step.dependOn(&gen_ruleset.step);
    b.installArtifact(exe);

    // From `zig init`
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
