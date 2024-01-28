const std = @import("std");
const raylib = @import("raylib");
const m = @import("../../utils/math.zig");

const Self = @This();

const Sprite = enum {
    hed,
    seg,
    tal,
};

pos: raylib.Vector2,
vel: raylib.Vector2,
dir: m.Dir,
size: f32,
sprite: Sprite,

// NOTE: this looks like a candidate for a struct argument
pub fn init(pos: raylib.Vector2, vel: raylib.Vector2, dir: m.Dir, size: f32) Self {
    return .{
        .pos = pos,
        .vel = vel,
        .dir = dir,
        .size = size,
        .sprite = .seg,
    };
}

pub fn setSprite(self: *Self, sprite: Sprite) void {
    self.sprite = sprite;
}

// NOTE: this method might also require a back collision pixel at high velocities
pub fn getFrontCollisionPixel(self: *Self) raylib.Vector2 {
    const halfSize = @divTrunc(self.size, 2);

    return switch (self.dir) {
        .up => raylib.Vector2{ .x = self.pos.x + halfSize, .y = self.pos.y },
        .down => raylib.Vector2{ .x = self.pos.x + halfSize, .y = self.pos.y + self.size },
        .left => raylib.Vector2{ .x = self.pos.x, .y = self.pos.y + halfSize },
        else => raylib.Vector2{ .x = self.pos.x + self.size, .y = self.pos.y + halfSize },
    };
}
