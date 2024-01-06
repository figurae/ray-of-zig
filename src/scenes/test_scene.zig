const std = @import("std");
const raylib = @import("raylib");

// NOTE: why does this work? I thought this should give
// an error because of importing files outside module path...
const gfx = @import("../gfx.zig");
const snd = @import("../snd.zig");
const fun = @import("../fun.zig");
const primitives = @import("../primitives.zig");
const assets = @import("../assets.zig");

const m = @import("../utils/math.zig");

const viewport = gfx.viewport;
const canvas = gfx.canvas;

var random: std.rand.Random = undefined;

var dancing_lines: [10]fun.DancingLine = undefined;

var sprite_x: f32 = 0;
var sprite_y: f32 = 0;

var timer: f32 = 0;
var note: i32 = 42;
var note_step: i32 = 3;

pub fn init(allocator: std.mem.Allocator) !void {
    try assets.init(allocator, &[_][]const u8{ "test2.bmp", "sprite.bmp", "font4x7.bmp" });

    var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
    random = pcg.random();

    for (&dancing_lines) |*line| {
        line.* = fun.DancingLine.init(&random, null, null, null, null, null);
    }

    try snd.init(allocator);
    try snd.addOscilator(@enumFromInt(note - note_step));
}

pub fn deinit(allocator: std.mem.Allocator) void {
    snd.deinit();
    assets.deinit(allocator);
}

pub fn update(dt: f32) !void {
    const dir = m.Vector2Direction;

    if (raylib.IsKeyDown(.KEY_D)) viewport.move(dir.right);
    if (raylib.IsKeyDown(.KEY_A)) viewport.move(dir.left);
    if (raylib.IsKeyDown(.KEY_W)) viewport.move(dir.up);
    if (raylib.IsKeyDown(.KEY_S)) viewport.move(dir.down);

    canvas.clear(raylib.RAYWHITE);

    gfx.drawSprite(.{ .x = 0, .y = 0 }, &assets.bitmaps.get("test2").?);

    if (raylib.IsKeyDown(.KEY_RIGHT)) sprite_x += 1;
    if (raylib.IsKeyDown(.KEY_LEFT)) sprite_x -= 1;
    if (raylib.IsKeyDown(.KEY_UP)) sprite_y -= 1;
    if (raylib.IsKeyDown(.KEY_DOWN)) sprite_y += 1;

    gfx.drawSprite(.{ .x = sprite_x, .y = sprite_y }, &assets.bitmaps.get("sprite").?);

    for (&dancing_lines) |*line| {
        line.update(dt);
        primitives.drawLine(
            line.pos_1,
            line.pos_2,
            line.color,
        );
    }

    timer += dt;

    if (timer > 0.3) {
        timer = 0;
        snd.getOscillator(0).play(@enumFromInt(note));

        if (note > 70 or note < 32) note_step = -note_step;
        note += note_step;
    }
}
