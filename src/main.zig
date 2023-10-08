const raylib = @import("raylib");
const engine = @import("engine.zig").Engine;

pub fn main() !void {
    engine.init();
    defer engine.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.update(raylib.GetFrameTime());
    }
}
