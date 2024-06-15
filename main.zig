//! followed https://zig.news/perky/hot-reloading-with-raylib-4bf9
const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

// TODO
// - watch the modified time on the configuration files inside main, if they've been modified, trigger a reload.
// - recompile the DLL on a separate thread to avoid the game freeze.
//     - tweak build system:
//         - write the game DLL to a temporary file
//         - unload, overwrite the DLL from the temporary one, and re-load.
// - draw the output of the compilation on-screen, maybe in a custom debug window or in-game console.

const screen_w = 400;
const screen_h = 200;

const GameStatePtr = *anyopaque;

var gameInit: *const fn () GameStatePtr = undefined;
var gameReload: *const fn (GameStatePtr) void = undefined;
var gameTick: *const fn (GameStatePtr) void = undefined;
var gameDraw: *const fn (GameStatePtr) void = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    loadGameDll() catch @panic("failed to load");

    const game_state = gameInit();

    c.InitWindow(screen_w, screen_h, "Zig Hot-Reload");
    c.SetTargetFPS(60);

    // WindowShouldClose will return true if the user presses ESC.
    while (!c.WindowShouldClose()) {
        if (c.IsKeyPressed(c.KEY_F5)) {
            unloadGameDll() catch unreachable;
            recompileGameDll(allocator) catch {
                std.debug.print("failed to recompile", .{});
            };
            loadGameDll() catch @panic("failed to load");
            gameReload(game_state);
        }
        gameTick(game_state);
        c.BeginDrawing();
        gameDraw(game_state);
        c.EndDrawing();
    }

    c.CloseWindow();
}

var game_dyn_lib: ?std.DynLib = null;
fn loadGameDll() !void {
    if (game_dyn_lib != null) return error.AlreadyLoaded;

    var dyn_lib = std.DynLib.open("zig-out/lib/libgame.1.0.0.dylib") catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;

    gameInit = dyn_lib.lookup(@TypeOf(gameInit), "gameInit") orelse return error.lookupFail;
    gameReload = dyn_lib.lookup(@TypeOf(gameReload), "gameReload") orelse return error.lookupFail;
    gameTick = dyn_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.lookupFail;
    gameDraw = dyn_lib.lookup(@TypeOf(gameDraw), "gameDraw") orelse return error.lookupFail;

    std.debug.print("Loaded dll\n", .{});
}

fn unloadGameDll() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

fn recompileGameDll(arena: std.mem.Allocator) !void {
    const process_args = [_][]const u8{
        "zig",
        "build",
        "-Dgame_only=true", // This '=true' is important!
        "--search-prefix",
        "/Users/ben/builds/raylib/zig-out/",
    };
    var build_process = std.process.Child.init(&process_args, arena);
    try build_process.spawn();
    // wait() returns a tagged union. If the compilations fails that union
    // will be in the state .{ .Exited = 2 }
    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.RecompileFail;
        },
        else => return,
    }
}
