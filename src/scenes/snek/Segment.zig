const std = @import("std");
const r = @import("raylib");
const m = @import("../../utils/math.zig");

const Self = @This();

const Sprite = enum {
    hed,
    seg,
    tal,
};

pos: r.Vector2,
vel: r.Vector2,
dir: m.Dir,
size: f32,
is_stopped: bool,
sprite: Sprite,

// NOTE: this looks like a candidate for a struct argument
pub fn init(pos: r.Vector2, vel: r.Vector2, dir: m.Dir, size: f32, is_stopped: bool) Self {
    return .{
        .pos = pos,
        .vel = vel,
        .dir = dir,
        .size = size,
        .is_stopped = is_stopped,
        .sprite = .seg,
    };
}

pub fn setSprite(self: *Self, sprite: Sprite) void {
    self.sprite = sprite;
}

// NOTE: this method might also require a back collision pixel at high velocities
pub fn getFrontCollisionPixel(self: *Self) r.Vector2 {
    const halfSize = @divTrunc(self.size, 2);

    return switch (self.dir) {
        .up => r.Vector2{ .x = self.pos.x + halfSize, .y = self.pos.y + 1 },
        .down => r.Vector2{ .x = self.pos.x + halfSize, .y = self.pos.y + self.size - 1 },
        .left => r.Vector2{ .x = self.pos.x + 1, .y = self.pos.y + halfSize },
        else => r.Vector2{ .x = self.pos.x + self.size - 1, .y = self.pos.y + halfSize },
    };
}
