const std = @import("std");
const r = @import("raylib");

const config = @import("../config.zig");
const gfx = @import("../gfx.zig");
const assets = @import("../assets.zig");
const debug = @import("../debug.zig");

const t = @import("../utils/types.zig");
const m = @import("../utils/math.zig");

const Segment = @import("snek/Segment.zig");
const V2D = m.Vector2Dir;

var pcg: std.rand.Pcg = undefined;
var random: std.rand.Random = undefined;

const segment_size = 10;
const initial_segment_count = 8;
const initial_speed = 40;
const max_speed = 240;
const speed_step = 5;
const input_buffer_duration = 0.2;
const input_buffer_size = 3;

// NOTE: this could be a custom stack implementation
var input_buffer: std.ArrayList(m.Dir) = undefined;
// NOTE: an idea - metaball segments!
var snek: std.ArrayList(Segment) = undefined;

const initial_pos = r.Vector2{
    .x = config.canvas_width / 2,
    .y = config.canvas_height / 2,
};
const initial_dir = .right;
var prev_pos: r.Vector2 = undefined;
var apple_pos: r.Vector2 = undefined;

var speed: f32 = initial_speed;
var counter: f32 = 0;
var should_grow = false;

var is_overlay_visible = true;

pub fn init(allocator: std.mem.Allocator) !void {
    // TODO: allow adding assets outside init to let debug inject the font on its own
    try assets.init(allocator, &[_][]const u8{
        "font4x7.bmp",
        "snek_seg.bmp",
        "snek_hed.bmp",
        "snek_tal.bmp",
        "apple.bmp",
    });

    var seed: u64 = undefined;
    try std.os.getrandom(std.mem.asBytes(&seed));
    pcg = std.rand.Pcg.init(seed);
    random = pcg.random();

    input_buffer = std.ArrayList(m.Dir).init(allocator);
    snek = std.ArrayList(Segment).init(allocator);
    try initializeSnek(initial_segment_count);

    spawnApple(&random);

    prev_pos = initial_pos;
}

pub fn deinit(_: std.mem.Allocator) void {
    input_buffer.deinit();
    snek.deinit();
}

pub fn update(dt: f32) !void {
    if (r.IsKeyPressed(.KEY_RIGHT)) try pushInputToBuffer(.right);
    if (r.IsKeyPressed(.KEY_LEFT)) try pushInputToBuffer(.left);
    if (r.IsKeyPressed(.KEY_UP)) try pushInputToBuffer(.up);
    if (r.IsKeyPressed(.KEY_DOWN)) try pushInputToBuffer(.down);

    gfx.canvas.clear(r.DARKBLUE);

    counter += dt;

    debug.overlay("speed: {d}\n", .{speed});
    debug.overlay("length: {d}\n", .{snek.items.len});

    if (counter >= input_buffer_duration) {
        // NOTE: this could be a little more elegant
        if (input_buffer.items.len > 0) {
            for (input_buffer.items.len - 1) |_| {
                _ = input_buffer.orderedRemove(0);
            }
        }
        counter = 0;
    }

    for (input_buffer.items) |item| {
        debug.overlay("{any}\n", .{item});
    }

    gfx.drawSprite(
        apple_pos,
        &assets.bitmaps.get("apple").?,
        .{},
    );

    {
        var i = snek.items.len;
        while (i > 0) {
            i -= 1;
            var seg = &snek.items[i];
            if (!seg.is_stopped) {
                seg.vel = r.Vector2Scale(V2D.get(seg.dir), speed * dt);
                seg.pos = r.Vector2Add(seg.pos, seg.vel);
            }
        }
    }

    try adjustSegmentsToGrid();

    for (snek.items) |seg| {
        const sprite_name = switch (seg.sprite) {
            .seg => "snek_seg",
            .hed => "snek_hed",
            else => "snek_tal",
        };

        gfx.drawSprite(
            seg.pos,
            &assets.bitmaps.get(sprite_name).?,
            .{ .dir = seg.dir },
        );
    }

    if (isCollidingWithObstacle()) try reset();
    if (isCollidingWithApple()) {
        should_grow = true;
        spawnApple(&random);
    }

    if (r.IsKeyPressed(.KEY_GRAVE)) is_overlay_visible = !is_overlay_visible;
    debug.displayOverlay(is_overlay_visible);
}

fn adjustSegmentsToGrid() !void {
    var snek_hed = &snek.items[0];

    if (@abs(snek_hed.pos.x - prev_pos.x) >= segment_size or
        @abs(snek_hed.pos.y - prev_pos.y) >= segment_size)
    {
        for (snek.items) |*seg| {
            seg.pos.x = roundToSegmentSize(seg.pos.x);
            seg.pos.y = roundToSegmentSize(seg.pos.y);
        }

        var i = snek.items.len - 1;
        while (i >= 1) : (i -= 1) {
            snek.items[i].dir = snek.items[i - 1].dir;
        }

        var last_seg = &snek.items[snek.items.len - 1];
        if (last_seg.is_stopped) last_seg.is_stopped = false;

        snek_hed.dir = readInputFromBuffer(snek_hed.dir);
        prev_pos = snek_hed.pos;

        if (should_grow) {
            try growSnek();
            should_grow = false;
        }
    }
}

fn reset() !void {
    try initializeSnek(initial_segment_count);
    speed = initial_speed;
}

fn isCollidingWithObstacle() bool {
    const p = snek.items[0].getFrontCollisionPixel();

    if (p.x < 0 or p.x >= config.canvas_width or
        p.y < 0 or p.y >= config.canvas_height)
    {
        return true;
    }

    for (snek.items[1..]) |seg| {
        if ((p.x >= seg.pos.x and p.x < seg.pos.x + segment_size) and
            (p.y >= seg.pos.y and p.y < seg.pos.y + segment_size))
        {
            return true;
        }
    }

    return false;
}

// NOTE: this can be definitely unified
fn isCollidingWithApple() bool {
    const p = snek.items[0].getFrontCollisionPixel();

    if ((p.x >= apple_pos.x and p.x < apple_pos.x + segment_size) and
        (p.y >= apple_pos.y and p.y < apple_pos.y + segment_size))
    {
        return true;
    }

    return false;
}

fn initializeSnek(segment_count: usize) !void {
    if (snek.items.len > 0) snek.clearAndFree();

    for (0..segment_count) |i| {
        var segment = Segment.init(
            r.Vector2Subtract(
                initial_pos,
                .{
                    .x = t.f32FromInt(i) * segment_size,
                    .y = 0,
                },
            ),
            .{ .x = 0, .y = 0 },
            initial_dir,
            segment_size,
            false,
        );

        if (i == 0) segment.setSprite(.hed);
        if (i == segment_count - 1) segment.setSprite(.tal);

        try snek.append(segment);
    }
}

fn growSnek() !void {
    var last_seg = &snek.items[snek.items.len - 1];
    var new_seg = Segment.init(last_seg.pos, r.Vector2Zero(), last_seg.dir, segment_size, true);

    new_seg.sprite = .tal;
    last_seg.sprite = .seg;

    try snek.append(new_seg);
    // NOTE: perhaps this should follow some kind of a curve
    if (speed < max_speed) speed += speed_step;
}

// FIXME: sometimes, the apple is spawned inside a segment
// I think a segment-sized collision map would help
fn spawnApple(rand: *std.rand.Random) void {
    var rand_pos = getRandomPos(rand);
    var found_target = false;

    while (r.Vector2Equals(rand_pos, apple_pos) != 0) {
        rand_pos = getRandomPos(rand);
    }

    while (!found_target) {
        restart: for (snek.items) |seg| {
            // TODO: factor out
            if ((rand_pos.x >= seg.pos.x and rand_pos.x < seg.pos.x + segment_size) and
                (rand_pos.y >= seg.pos.y and rand_pos.y < seg.pos.y + segment_size))
            {
                rand_pos = getRandomPos(rand);
                break :restart;
            }
        }
        found_target = true;
    }

    apple_pos = rand_pos;
}

fn getRandomPos(rand: *std.rand.Random) r.Vector2 {
    return .{
        .x = @round(rand.float(f32) * (@divTrunc(config.canvas_width, segment_size) - 1)) * segment_size,
        .y = @round(rand.float(f32) * (@divTrunc(config.canvas_height, segment_size) - 1)) * segment_size,
    };
}

fn readInputFromBuffer(current_dir: m.Dir) m.Dir {
    for (input_buffer.items.len) |_| {
        const new_dir = input_buffer.orderedRemove(0);
        if (new_dir == m.reverseDir(current_dir)) continue else return new_dir;
    }

    return current_dir;
}

fn pushInputToBuffer(input: m.Dir) !void {
    if (input_buffer.getLastOrNull() == input) return;

    const buffer_len = input_buffer.items.len;
    if (buffer_len == 0 and input == m.reverseDir(snek.items[0].dir)) return;

    try input_buffer.append(input);
    if (buffer_len > input_buffer_size) {
        _ = input_buffer.orderedRemove(0);
    }

    counter = 0;
}

fn roundToSegmentSize(val: f32) f32 {
    // NOTE: this still has a tendency to be a bit jerky at high speeds, though maybe it's because
    // of square segments w/o joints; also, try to manually find closest snap-to-segment values?
    return @round(val / segment_size) * segment_size;
}
