const std = @import("std");
const raylib = @import("raylib");
const engine = @import("engine.zig");

pub fn main() !void {
    try engine.init();
    defer engine.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.update(raylib.GetFrameTime());
    }
}
