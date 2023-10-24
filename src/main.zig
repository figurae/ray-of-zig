const std = @import("std");

const raylib = @import("raylib");
const engine = @import("engine.zig").Engine;

pub fn main() !void {
    // NOTE: there is something in build that doesn't
    // add \n to last build message. might want to investigate one day...
    std.debug.print("\n", .{});

    try engine.init();
    defer engine.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.update(raylib.GetFrameTime());
    }
}
