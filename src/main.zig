const std = @import("std");
const raylib = @import("raylib");

pub fn main() void {
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    raylib.InitWindow(800, 800, "hello world!");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    const width = 300;
    const height = 300;

    var rand = std.rand.Pcg.init(69);

    var pixels = [_]raylib.Color{undefined} ** (width * height);

    for (&pixels) |*pixel| {
        if (rand.random().boolean())
            pixel.* = raylib.PINK
        else
            pixel.* = raylib.BEIGE;
    }

    const image = raylib.Image{
        .data = &pixels,
        .width = width,
        .height = height,
        .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
        .mipmaps = 1,
    };

    const texture = raylib.LoadTextureFromImage(image);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawFPS(10, 10);

        raylib.DrawTexture(texture, 10, 10, raylib.WHITE);
    }
}
