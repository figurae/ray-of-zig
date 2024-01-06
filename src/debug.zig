const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const assets = @import("assets.zig");

const t = @import("utils/types.zig");

const font_width = 4;
const font_height = 7;
const font_horizontal_padding = 1;
const font_vertical_padding = 3;
const screen_horizontal_padding = 7;
const extra_left_margin = 1; // font dependent
const screen_vertical_padding = 4;
const extra_top_margin = 1; // font dependent

const window_width = config.canvas_width - 2 * screen_horizontal_padding;
const window_height = config.canvas_height - 2 * screen_vertical_padding;

const col_count = @divTrunc(
    window_width,
    font_width + font_horizontal_padding,
);
const row_count = @divTrunc(
    window_height,
    font_height + font_vertical_padding,
);
const character_count = col_count * row_count;
const last_line_start = character_count - col_count;

var log_buffer = [_]u8{32} ** character_count;
var log_index: usize = 0;

var overlay_buffer = [_]u8{32} ** character_count;
var overlay_index: usize = 0;

pub fn print(text: []const u8) void {
    for (text) |char| {
        if (log_index >= character_count) {
            log_index = last_line_start;
            moveAllLinesUp();
        }

        if (char == '\n') {
            log_index = findNextLineStart();
            continue;
        }

        log_buffer[log_index] = char;
        log_index += 1;
    }
}

pub fn displayLog() void {
    for (0..row_count) |row| {
        const range_start = row * col_count;
        const range_end = range_start + col_count;
        const y =
            t.f32FromInt(screen_vertical_padding + extra_top_margin +
            row * (font_height + font_vertical_padding));

        gfx.drawText(
            log_buffer[range_start..range_end],
            .{ .x = t.f32FromInt(screen_horizontal_padding + extra_left_margin), .y = y },
            &assets.bitmaps.get("font4x7").?,
            raylib.RED,
        );
    }
}

fn findNextLineStart() usize {
    // NOTE: must we always start at 0?
    var i: usize = 0;
    while (i < character_count) : (i += col_count) {
        if (i > log_index) return i;
    }

    // NOTE: maybe unify this with the one inside print()
    moveAllLinesUp();
    return last_line_start;
}

fn moveAllLinesUp() void {
    for (log_buffer[0..last_line_start], log_buffer[col_count..character_count]) |*top_char, *bottom_char| {
        top_char.* = bottom_char.*;
    }
    for (log_buffer[last_line_start..character_count]) |*char| {
        char.* = ' ';
    }
}
