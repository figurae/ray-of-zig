const std = @import("std");
const r = @import("raylib");
const engine = @import("engine.zig");

pub fn main() !void {
    try engine.init();
    defer engine.deinit();

    while (!r.WindowShouldClose()) {
        try engine.update(r.GetFrameTime());
    }
}
