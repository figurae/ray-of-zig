const std = @import("std");
const raylib = @import("raylib");

const config = @import("../config.zig");
const gfx = @import("../gfx.zig");
const assets = @import("../assets.zig");
const debug = @import("../debug.zig");

const t = @import("../utils/types.zig");
const m = @import("../utils/math.zig");

const Segment = @import("snek/Segment.zig");
const dir = m.Vector2Direction;

const segment_size = 10;

var snek: std.ArrayList(Segment) = undefined;

const initial_pos = raylib.Vector2{ .x = config.canvas_width / 2, .y = config.canvas_height / 2 };
const initial_dir = dir.right;
var prev_pos: raylib.Vector2 = undefined;

var speed: f32 = 40;
var player_dir: raylib.Vector2 = undefined;

var is_overlay_visible = true;

pub fn init(allocator: std.mem.Allocator) !void {
    // TODO: allow adding assets outside init to let debug inject the font on its own
    try assets.init(allocator, &[_][]const u8{
        "font4x7.bmp",
    });
    snek = std.ArrayList(Segment).init(allocator);
    try appendToSnek(&snek, 8);

    player_dir = initial_dir;
    prev_pos = initial_pos;
}

pub fn deinit(_: std.mem.Allocator) void {
    snek.deinit();
}

pub fn update(dt: f32) !void {
    gfx.canvas.clear(raylib.DARKBLUE);

    var snek_hed = &snek.items[0];
    if (@abs(snek_hed.pos.x - prev_pos.x) >= segment_size or @abs(snek_hed.pos.y - prev_pos.y) >= segment_size) {
        for (snek.items) |*seg| {
            seg.pos.x = roundToSegmentSize(seg.pos.x);
            seg.pos.y = roundToSegmentSize(seg.pos.y);
        }

        var i = snek.items.len - 1;
        while (i >= 1) : (i -= 1) {
            snek.items[i].dir = snek.items[i - 1].dir;
        }

        snek_hed.dir = player_dir;
        prev_pos = snek_hed.pos;
    }

    for (snek.items) |*seg| {
        seg.*.vel = raylib.Vector2Scale(seg.dir, speed * dt);
        seg.*.pos = raylib.Vector2Add(seg.pos, seg.vel);

        drawSegment(seg.pos);
    }

    if (raylib.IsKeyDown(.KEY_RIGHT)) player_dir = dir.right;
    if (raylib.IsKeyDown(.KEY_LEFT)) player_dir = dir.left;
    if (raylib.IsKeyDown(.KEY_UP)) player_dir = dir.up;
    if (raylib.IsKeyDown(.KEY_DOWN)) player_dir = dir.down;

    if (raylib.IsKeyPressed(.KEY_GRAVE)) is_overlay_visible = !is_overlay_visible;
    debug.displayOverlay(is_overlay_visible);
}

fn drawSegment(pos: raylib.Vector2) void {
    for (0..segment_size) |x| {
        for (0..segment_size) |y| {
            gfx.drawPixel(raylib.Vector2Add(pos, .{ .x = t.f32FromInt(x), .y = t.f32FromInt(y) }), raylib.BEIGE);
        }
    }
}

fn appendToSnek(target_snek: *std.ArrayList(Segment), segment_count: usize) !void {
    for (0..segment_count) |i| {
        try target_snek.append(Segment.init(
            raylib.Vector2Subtract(
                initial_pos,
                .{
                    .x = t.f32FromInt(i) * segment_size,
                    .y = 0,
                },
            ),
            .{ .x = 0, .y = 0 },
            initial_dir,
        ));
    }
}

fn roundToSegmentSize(val: f32) f32 {
    // NOTE: this still has a tendency to be a bit jerky at high speeds, though maybe it's because
    // of square segments w/o joints; also, try to manually find closest snap-to-segment values?
    return @round(val / segment_size) * segment_size;
}
