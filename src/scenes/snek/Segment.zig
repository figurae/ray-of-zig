const std = @import("std");
const raylib = @import("raylib");
const m = @import("../../utils/math.zig");

const Self = @This();

pos: raylib.Vector2,
vel: raylib.Vector2,
dir: m.Dir,

pub fn init(pos: raylib.Vector2, vel: raylib.Vector2, dir: m.Dir) Self {
    return .{
        .pos = pos,
        .vel = vel,
        .dir = dir,
    };
}
