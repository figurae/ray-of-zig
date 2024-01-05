const std = @import("std");
const raylib = @import("raylib");

const config = @import("../config.zig");
const gfx = @import("../gfx.zig");

const t = @import("../utils/types.zig");
const m = @import("../utils/math.zig");

const dir = m.Vector2Direction;
const segment_size = 10;

var head_pos = raylib.Vector2{ .x = config.canvas_width / 2 - segment_size / 2, .y = config.canvas_height / 2 - segment_size / 2 };
var speed: f32 = 20;
var direction = dir.right;
var timer = 10;

pub fn init(allocator: std.mem.Allocator) !void {
    _ = allocator; // autofix
}

pub fn deinit(allocator: std.mem.Allocator) void {
    _ = allocator; // autofix
}

pub fn update(dt: f32) !void {
    gfx.canvas.clear(raylib.DARKBLUE);

    const velocity = raylib.Vector2Scale(direction, speed * dt);
    head_pos = raylib.Vector2Add(head_pos, velocity);

    drawSegment(head_pos);

    if (raylib.IsKeyDown(.KEY_RIGHT)) direction = dir.right;
    if (raylib.IsKeyDown(.KEY_LEFT)) direction = dir.left;
    if (raylib.IsKeyDown(.KEY_UP)) direction = dir.up;
    if (raylib.IsKeyDown(.KEY_DOWN)) direction = dir.down;
}

fn drawSegment(pos: raylib.Vector2) void {
    for (0..segment_size) |x| {
        for (0..segment_size) |y| {
            gfx.drawPixel(raylib.Vector2Add(pos, .{ .x = t.f32FromInt(x), .y = t.f32FromInt(y) }), raylib.BEIGE);
        }
    }
}
