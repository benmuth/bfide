const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const max_input_chars: u8 = 9;

const Editor = struct {
    allocator: std.mem.Allocator,

    text_box: rl.Rectangle = .{ .x = 800 / 2.0 - 100, .y = 180, .width = 225, .height = 50 },
    mouse_on_text: bool = false,

    text: [*c]u8,

    frames_counter: u32 = 0,

    letter_count: u32 = 0,

    window_width: c_int = 200,
    window_height: c_int = 200,
};

const config_filepath = "config/radius.txt";

const text_box: rl.Rectangle = .{};

export fn init(window_width: c_int, window_height: c_int) *anyopaque {
    var allocator = std.heap.c_allocator;
    const editor_state = allocator.create(Editor) catch @panic("out of memory.");
    editor_state.* = .{
        .allocator = allocator,
        .text = allocator.allocSentinel(u8, 9, 0) catch @panic("out of memory."),
        .window_width = window_width,
        .window_height = window_height,
    };
    return editor_state;
}

export fn reload(editor_state_ptr: *anyopaque) void {
    var editor_state: *Editor = @ptrCast(@alignCast(editor_state_ptr));
    editor_state.frames_counter = 0;
}

export fn draw(editor_state_ptr: *anyopaque) void {
    const editor_state: *Editor = @ptrCast(@alignCast(editor_state_ptr));

    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);

    rl.DrawText("PLACE MOUSE OVER INPUT BOX!", 240, 140, 20, rl.GRAY);

    // rl.DrawRectangleRec(editor_state.text_box, rl.LIGHTGRAY);
    if (editor_state.mouse_on_text) {
        rl.DrawRectangleLines(
            @as(c_int, @intFromFloat(editor_state.text_box.x)),
            @as(c_int, @intFromFloat(editor_state.text_box.y)),
            @as(c_int, @intFromFloat(editor_state.text_box.width)),
            @as(c_int, @intFromFloat(editor_state.text_box.height)),
            rl.RED,
        );
    } else {
        rl.DrawRectangleLines(
            @as(c_int, @intFromFloat(editor_state.text_box.x)),
            @as(c_int, @intFromFloat(editor_state.text_box.y)),
            @as(c_int, @intFromFloat(editor_state.text_box.width)),
            @as(c_int, @intFromFloat(editor_state.text_box.height)),
            rl.DARKGRAY,
        );
    }

    rl.DrawText(editor_state.text, @as(c_int, @intFromFloat(editor_state.text_box.x + 5)), @as(c_int, @intFromFloat(editor_state.text_box.y + 8)), 40, rl.MAROON);

    rl.DrawText(rl.TextFormat("INPUT CHARS: %i/%i", editor_state.letter_count, max_input_chars), 315, 250, 20, rl.DARKGRAY);

    if (editor_state.mouse_on_text) {
        if (editor_state.letter_count < max_input_chars) {
            // Draw blinking underscore char
            if (((editor_state.frames_counter / 20) % 2) == 0) {
                rl.DrawText(
                    "_",
                    @as(c_int, @intFromFloat(editor_state.text_box.x)) + 8 + rl.MeasureText(editor_state.text, 40),
                    @as(c_int, @intFromFloat(editor_state.text_box.y + 12)),
                    40,
                    rl.MAROON,
                );
            }
        } else {
            rl.DrawText("Press BACKSPACE to delete chars...", 230, 300, 20, rl.GRAY);
        }
    }

    rl.EndDrawing();
}

export fn update(editor_state_ptr: *anyopaque) void {
    const editor_state: *Editor = @ptrCast(@alignCast(editor_state_ptr));

    editor_state.mouse_on_text = rl.CheckCollisionPointRec(rl.GetMousePosition(), editor_state.text_box);

    if (editor_state.mouse_on_text) {
        rl.SetMouseCursor(rl.MOUSE_CURSOR_IBEAM);

        var key: u8 = @as(u8, @intCast(rl.GetCharPressed()));

        while (key > 0) : (key = @as(u8, @intCast(rl.GetCharPressed()))) {
            if ((key >= 32) and (key <= 125) and (editor_state.letter_count < max_input_chars)) {
                editor_state.text[editor_state.letter_count] = key;
                editor_state.letter_count += 1;
            }
        }

        if (rl.IsKeyPressed(rl.KEY_BACKSPACE)) {
            editor_state.letter_count -= 1;
            if (editor_state.letter_count < 0) editor_state.letter_count = 0;
        }
    } else {
        rl.SetMouseCursor(rl.MOUSE_CURSOR_DEFAULT);
    }

    if (editor_state.mouse_on_text) {
        editor_state.frames_counter += 1;
    } else {
        editor_state.frames_counter = 0;
    }
}
