const std = @import("std");
const raylib = @import("raylib");

const config = @import("../config.zig");
const gfx = @import("../gfx.zig");
const assets = @import("../assets.zig");
const debug = @import("../debug.zig");

const t = @import("../utils/types.zig");
const m = @import("../utils/math.zig");

const Segment = @import("snek/Segment.zig");
const V2D = m.Vector2Dir;

const segment_size = 10;
const input_buffer_duration = 0.2;
const input_buffer_size = 3;

// NOTE: an idea - metaball segments!
var input_buffer: std.ArrayList(m.Dir) = undefined;
var snek: std.ArrayList(Segment) = undefined;

const initial_pos = raylib.Vector2{ .x = config.canvas_width / 2, .y = config.canvas_height / 2 };
const initial_dir = .right;
var prev_pos: raylib.Vector2 = undefined;

var speed: f32 = 40;
var counter: f32 = 0;

var is_overlay_visible = true;

pub fn init(allocator: std.mem.Allocator) !void {
    // TODO: allow adding assets outside init to let debug inject the font on its own
    try assets.init(allocator, &[_][]const u8{
        "font4x7.bmp",
        "snek_seg.bmp",
        "snek_hed.bmp",
        "snek_tal.bmp",
    });

    input_buffer = std.ArrayList(m.Dir).init(allocator);
    snek = std.ArrayList(Segment).init(allocator);
    try appendToSnek(&snek, 8);

    prev_pos = initial_pos;
}

pub fn deinit(_: std.mem.Allocator) void {
    snek.deinit();
}

pub fn update(dt: f32) !void {
    gfx.canvas.clear(raylib.DARKBLUE);

    counter += dt;
    debug.overlay("{d}\n", .{counter});

    if (counter >= input_buffer_duration) {
        // NOTE: this could be a little more elegant
        if (input_buffer.items.len > 0) {
            for (0..input_buffer.items.len - 1) |_| {
                _ = input_buffer.orderedRemove(0);
            }
        }
        counter = 0;
    }

    for (input_buffer.items) |item| {
        debug.overlay("{any}\n", .{item});
    }

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

        snek_hed.dir = if (input_buffer.items.len > 0) input_buffer.orderedRemove(0) else snek_hed.dir;
        prev_pos = snek_hed.pos;
    }

    {
        var i = snek.items.len;
        while (i > 0) {
            i -= 1;
            var seg = &snek.items[i];
            seg.vel = raylib.Vector2Scale(V2D.get(seg.dir), speed * dt);
            seg.pos = raylib.Vector2Add(seg.pos, seg.vel);

            const sprite_name = switch (seg.sprite) {
                .seg => "snek_seg",
                .hed => "snek_hed",
                else => "snek_tal",
            };

            gfx.drawSprite(seg.pos, &assets.bitmaps.get(sprite_name).?, .{ .dir = seg.dir });
        }
    }

    if (raylib.IsKeyPressed(.KEY_RIGHT)) try pushInputToBuffer(.right);
    if (raylib.IsKeyPressed(.KEY_LEFT)) try pushInputToBuffer(.left);
    if (raylib.IsKeyPressed(.KEY_UP)) try pushInputToBuffer(.up);
    if (raylib.IsKeyPressed(.KEY_DOWN)) try pushInputToBuffer(.down);

    if (raylib.IsKeyPressed(.KEY_GRAVE)) is_overlay_visible = !is_overlay_visible;
    debug.displayOverlay(is_overlay_visible);
}

fn appendToSnek(target_snek: *std.ArrayList(Segment), segment_count: usize) !void {
    for (0..segment_count) |i| {
        var segment = Segment.init(
            raylib.Vector2Subtract(
                initial_pos,
                .{
                    .x = t.f32FromInt(i) * segment_size,
                    .y = 0,
                },
            ),
            .{ .x = 0, .y = 0 },
            initial_dir,
        );

        if (i == 0) segment.setSprite(.hed);
        if (i == segment_count - 1) segment.setSprite(.tal);

        try target_snek.append(segment);
    }
}

fn pushInputToBuffer(input: m.Dir) !void {
    try input_buffer.append(input);
    if (input_buffer.items.len > input_buffer_size) {
        _ = input_buffer.orderedRemove(0);
    }

    counter = 0;
}

fn roundToSegmentSize(val: f32) f32 {
    // NOTE: this still has a tendency to be a bit jerky at high speeds, though maybe it's because
    // of square segments w/o joints; also, try to manually find closest snap-to-segment values?
    return @round(val / segment_size) * segment_size;
}
