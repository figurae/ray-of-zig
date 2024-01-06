const std = @import("std");
const raylib = @import("raylib");

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

pub fn init(allocator: std.mem.Allocator) !void {
    try assets.init(allocator, &[_][]const u8{
        "test2.bmp",
        "sprite.bmp",
        "font4x7.bmp",
    });

    var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
    random = pcg.random();

    for (&dancing_lines) |*line| {
        line.* = DancingLine.init(&random, null, null, null, null, null);
    }

    try snd.init(allocator);
    try snd.addOscilator(@enumFromInt(note - note_step));

    debug.print("1. test\n");
    debug.print("2. test2\n");
    debug.print("3. The quick brown fox jumps over the lazy dog.\n");
    debug.print("4. The quick brown fox jumps over the lazy dog. ");
    debug.print("5. The quick brown fox jumps over the lazy dog. ");
    debug.print("6. The quick brown fox jumps over the lazy dog. ");
    debug.print("7. The quick brown fox jumps over the lazy dog. ");
    debug.print("8. The quick brown fox jumps over the lazy dog. ");
    debug.print("9. The quick brown fox jumps over the lazy dog. ");
    debug.print("10. The quick brown fox jumps over the lazy dog. ");
    debug.print("11. The quick brown fox jumps over the lazy dog. ");
    debug.print("12. The quick brown fox jumps over the lazy dog. ");
    debug.print("13. The quick brown fox jumps over the lazy dog. ");
    debug.print("14. The quick brown fox jumps over the lazy dog. ");
    debug.print("15. The quick brown fox jumps over the lazy dog. ");
    debug.print("16. The quick brown fox jumps over the lazy dog. ");
    debug.print("17. The quick brown fox jumps over the lazy dog. ");
    debug.print("18. The quick brown fox jumps over the lazy dog. ");
    debug.print("19. The quick brown fox jumps over the lazy dog. ");
    debug.print("20. The quick brown fox jumps over the lazy dog. ");
    debug.print("21. The quick brown fox jumps over the lazy dog. ");
    debug.print("22. ajajajaj, aj aj amr\n");
    debug.print("23. aj mi korenoooo");
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
        shapes.drawLine(
            line.pos_1,
            line.pos_2,
            line.color,
        );
    }

    debug.displayLog();

    timer += dt;

    if (timer > 0.3) {
        timer = 0;
        snd.getOscillator(0).play(@enumFromInt(note));

        if (note > 70 or note < 32) note_step = -note_step;
        note += note_step;
    }
}
