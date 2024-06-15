const std = @import("std");

pub fn build(b: *std.Build) void {
    const editor_only = b.option(bool, "editor_only", "only build editor") orelse false;
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

    const editor_lib = b.addSharedLibrary(.{
        .name = "editor",
        .root_source_file = .{ .src_path = .{ .sub_path = "editor.zig", .owner = b } },
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    editor_lib.linkLibrary(raylib_dep.artifact("raylib"));
    editor_lib.linkFramework("CoreVideo");
    editor_lib.linkFramework("IOKit");
    editor_lib.linkFramework("Cocoa");
    editor_lib.linkFramework("GLUT");
    editor_lib.linkFramework("OpenGL");
    editor_lib.linkLibC();

    b.installArtifact(editor_lib);

    // recompile the whole thing if not passed '-editor_only=true'
    if (!editor_only) {
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
