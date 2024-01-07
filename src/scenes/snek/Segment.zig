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
sprite: Sprite,

pub fn init(pos: raylib.Vector2, vel: raylib.Vector2, dir: m.Dir) Self {
    return .{
        .pos = pos,
        .vel = vel,
        .dir = dir,
        .sprite = .seg,
    };
}

pub fn setSprite(self: *Self, sprite: Sprite) void {
    self.sprite = sprite;
}
