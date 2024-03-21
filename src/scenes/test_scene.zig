const std = @import("std");
const r = @import("raylib");

// NOTE: why does '../' work now? I thought it should give
// an error because of importing files outside module path
const gfx = @import("../gfx.zig");
const snd = @import("../snd.zig");
const shapes = @import("../shapes.zig");
const assets = @import("../assets.zig");
const debug = @import("../debug.zig");

const m = @import("../utils/math.zig");

const DancingLine = @import("./test_scene/DancingLine.zig");
const viewport = gfx.viewport;
const canvas = gfx.canvas;

var random: std.rand.Random = undefined;

var dancing_lines: [10]DancingLine = undefined;

var sprite_x: f32 = 0;
var sprite_y: f32 = 0;

var timer: f32 = 0;
var note: i32 = 42;
var note_step: i32 = 3;

var is_overlay_visible = true;

pub fn init(allocator: std.mem.Allocator) !void {
    try assets.init(allocator, &[_][]const u8{
        "test2.bmp",
        "sprite.bmp",
        "feels_good_transparent.bmp",
    });
    try debug.init(allocator);

    var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
    random = pcg.random();

    for (&dancing_lines) |*line| {
        line.* = DancingLine.init(&random, null, null, null, null, null);
    }

    try snd.init(allocator);
    try snd.addOscilator(@enumFromInt(note - note_step));

    debug.log("Here's some nice debug information!\n", .{});
    debug.log("I can do newlines and overflow the screen!\n\n", .{});
    debug.log("Starting note: {d}\n", .{note});
}

pub fn deinit(allocator: std.mem.Allocator) void {
    snd.deinit();
    debug.deinit(allocator);
    assets.deinit(allocator);
}

pub fn update(dt: f32) !void {
    const V2D = m.Vector2Dir;

    if (r.IsKeyDown(.KEY_D)) viewport.move(V2D.get(.right));
    if (r.IsKeyDown(.KEY_A)) viewport.move(V2D.get(.left));
    if (r.IsKeyDown(.KEY_W)) viewport.move(V2D.get(.up));
    if (r.IsKeyDown(.KEY_S)) viewport.move(V2D.get(.down));

    canvas.clear(r.RAYWHITE);

    gfx.drawSprite(.{ .x = 0, .y = 0 }, &assets.bitmaps.get("test2").?, .{});

    if (r.IsKeyDown(.KEY_RIGHT)) sprite_x += 1;
    if (r.IsKeyDown(.KEY_LEFT)) sprite_x -= 1;
    if (r.IsKeyDown(.KEY_UP)) sprite_y -= 1;
    if (r.IsKeyDown(.KEY_DOWN)) sprite_y += 1;

    gfx.drawSprite(.{ .x = sprite_x, .y = sprite_y }, &assets.bitmaps.get("sprite").?, .{});

    for (&dancing_lines) |*line| {
        line.update(dt);
        shapes.drawLine(
            line.pos_1,
            line.pos_2,
            line.color,
        );
    }

    gfx.drawSprite(.{ .x = 50, .y = 20 }, &assets.bitmaps.get("feels_good_transparent").?, .{});

    debug.overlay("sprite_x: {d}\nsprite_y: {d}\n", .{ sprite_x, sprite_y });
    debug.displayOverlay(is_overlay_visible);

    if (r.IsKeyDown(.KEY_GRAVE)) debug.displayLog();
    if (r.IsKeyPressed(.KEY_Z)) is_overlay_visible = !is_overlay_visible;

    timer += dt;

    if (timer > 0.3) {
        timer = 0;
        snd.getOscillator(0).play(@enumFromInt(note));

        if (note > 70 or note < 32) note_step = -note_step;
        note += note_step;
    }
}
