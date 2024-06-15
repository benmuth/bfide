const std = @import("std");

pub fn build(b: *std.Build) void {
    const game_only = b.option(bool, "game_only", "only build game") orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (target.result.os.tag != .macos) {
        @panic("Unsupported OS");
    }

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        .shared = true,
    });

    const game_lib = b.addSharedLibrary(.{
        .name = "game",
        .root_source_file = .{ .src_path = .{ .sub_path = "game.zig", .owner = b } },
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    game_lib.linkLibrary(raylib_dep.artifact("raylib"));
    game_lib.linkFramework("CoreVideo");
    game_lib.linkFramework("IOKit");
    game_lib.linkFramework("Cocoa");
    game_lib.linkFramework("GLUT");
    game_lib.linkFramework("OpenGL");
    game_lib.linkLibC();

    b.installArtifact(game_lib);

    // recompile the whole thing if not passed '-Dgame_only=true'
    if (!game_only) {
        const exe = b.addExecutable(.{
            .name = "no_hotreload",
            .root_source_file = .{ .src_path = .{ .sub_path = "main.zig", .owner = b } },
            .target = target,
            .optimize = optimize,
        });

        // Link to the Raylib and its required dependencies for macOS.
        exe.linkLibrary(raylib_dep.artifact("raylib"));
        exe.linkFramework("CoreVideo");
        exe.linkFramework("IOKit");
        exe.linkFramework("Cocoa");
        exe.linkFramework("GLUT");
        exe.linkLibC();

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }
}
