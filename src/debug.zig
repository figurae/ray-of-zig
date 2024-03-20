const std = @import("std");
const r = @import("raylib");

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

pub fn init(allocator: std.mem.Allocator) !void {
    try assets.add(allocator, &[_][]const u8{"font4x7.bmp"});
}

pub fn deinit(allocator: std.mem.Allocator) void {
    assets.remove(allocator, "font4x7");
}

pub fn log(comptime text: []const u8, args: anytype) void {
    writeToBuffer(text, args, &log_buffer, &log_index);
}

pub fn overlay(comptime text: []const u8, args: anytype) void {
    writeToBuffer(text, args, &overlay_buffer, &overlay_index);
}

pub fn displayLog() void {
    displayBuffer(&log_buffer);
}

pub fn displayOverlay(show_overlay: bool) void {
    if (show_overlay) displayBuffer(&overlay_buffer);
    clearBuffer(&overlay_buffer, &overlay_index);
}

fn writeToBuffer(
    comptime text: []const u8,
    args: anytype,
    buffer: *[character_count]u8,
    index: *usize,
) void {
    var buf: [character_count]u8 = undefined;
    const formatted_text = std.fmt.bufPrint(&buf, text, args) catch "<text formatting error>";

    for (formatted_text) |char| {
        if (index.* >= character_count) {
            index.* = last_line_start;
            moveAllLinesUp(buffer);
        }

        if (char == '\n') {
            index.* = findNextLineStart(buffer, index.*);
            continue;
        }

        buffer[index.*] = char;
        index.* += 1;
    }
}

fn displayBuffer(buffer: *[character_count]u8) void {
    for (0..row_count) |row| {
        const range_start = row * col_count;
        const range_end = range_start + col_count;
        const y =
            t.f32FromInt(screen_vertical_padding + extra_top_margin +
            row * (font_height + font_vertical_padding));

        gfx.drawText(
            buffer[range_start..range_end],
            .{ .x = t.f32FromInt(screen_horizontal_padding + extra_left_margin), .y = y },
            &assets.bitmaps.get("font4x7").?,
            r.RED,
        );
    }
}

fn clearBuffer(buffer: *[character_count]u8, index: *usize) void {
    for (buffer) |*char| {
        char.* = ' ';
    }
    index.* = 0;
}

fn findNextLineStart(buffer: *[character_count]u8, index: usize) usize {
    // NOTE: must we always start at 0?
    var i: usize = 0;
    while (i < character_count) : (i += col_count) {
        if (i > index) return i;
    }

    // NOTE: maybe unify this with the one inside print()
    moveAllLinesUp(buffer);
    return last_line_start;
}

// NOTE: I think this could be avoided by using a better data structure
fn moveAllLinesUp(buffer: *[character_count]u8) void {
    for (buffer[0..last_line_start], buffer[col_count..character_count]) |*top_char, *bottom_char| {
        top_char.* = bottom_char.*;
    }
    for (buffer[last_line_start..character_count]) |*char| {
        char.* = ' ';
    }
}
