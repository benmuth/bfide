const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const GameState = struct {
    allocator: std.mem.Allocator,
    time: f32 = 0,
    radius: f32 = 0,
};

const screen_w = 400;
const screen_h = 200;
const config_filepath = "config/radius.txt";

export fn gameInit() *anyopaque {
    var allocator = std.heap.c_allocator;
    const game_state = allocator.create(GameState) catch @panic("out of memory.");
    game_state.* = GameState{
        .allocator = allocator,
        .radius = readRadiusConfig(allocator),
    };
    return game_state;
}

export fn gameReload(game_state_ptr: *anyopaque) void {
    var game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    game_state.radius = readRadiusConfig(game_state.allocator);
}

export fn gameTick(game_state_ptr: *anyopaque) void {
    var game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    game_state.time += rl.GetFrameTime();
}

export fn gameDraw(game_state_ptr: *anyopaque) void {
    const game_state: *GameState = @ptrCast(@alignCast(game_state_ptr));
    rl.ClearBackground(rl.RAYWHITE);

    // Create zero terminated string with the time and radius.
    var buf: [256]u8 = undefined;
    const slice = std.fmt.bufPrintZ(
        &buf,
        "time: {d:.02}, radius: {d:.02}",
        .{ game_state.time, game_state.radius },
    ) catch "error";
    rl.DrawText(slice, 10, 10, 20, rl.GREEN);

    // Draw a circle moving across the screen with the config radius.
    const circle_x: f32 = @mod(game_state.time * 50.0, screen_w);
    rl.DrawCircleV(.{ .x = circle_x, .y = screen_h / 2 }, game_state.radius, rl.RED);
}

fn readRadiusConfig(allocator: std.mem.Allocator) f32 {
    const default_value: f32 = 30.0;

    // Read the text data from a file, if that fails, early-out with a default value.
    const config_data = std.fs.cwd().readFileAlloc(allocator, config_filepath, 1024 * 1024) catch {
        std.debug.print("Failed to read {s}\n", .{config_filepath});
        return default_value;
    };

    const data = std.mem.trim(u8, config_data, "\n \t");
    // Attempt to parse that text data into a float and return it, if that fails,
    // return a default value.
    return std.fmt.parseFloat(f32, data) catch {
        std.debug.print("Failed to parse {s}\n", .{config_filepath});
        return default_value;
    };
}
