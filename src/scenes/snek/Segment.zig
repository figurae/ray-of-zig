const std = @import("std");
const raylib = @import("raylib");

const Self = @This();

pos: raylib.Vector2,
vel: raylib.Vector2,
dir: raylib.Vector2,

pub fn init(pos: raylib.Vector2, vel: raylib.Vector2, dir: raylib.Vector2) Self {
    return .{
        .pos = pos,
        .vel = vel,
        .dir = dir,
    };
}
