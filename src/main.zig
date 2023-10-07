const std = @import("std");
const raylib = @import("raylib");

const canvas_width = 320;
const canvas_height = 180;

const window_width = 1920;
const window_height = 1080;

const Canvas = struct {
    width: i32,
    height: i32,
    pixels: [canvas_width * canvas_height]raylib.Color,
};

pub fn main() void {
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });

    raylib.InitWindow(window_width, window_height, "ray-of-zig");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    var rand = std.rand.Pcg.init(69);

    var canvas = Canvas{
        .width = canvas_width,
        .height = canvas_height,
        .pixels = [_]raylib.Color{raylib.WHITE} ** (canvas_width * canvas_height),
    };

    for (&canvas.pixels) |*pixel| {
        if (rand.random().boolean())
            pixel.* = raylib.PINK
        else
            pixel.* = raylib.RED;
    }

    const image = raylib.Image{
        .data = &canvas.pixels,
        .width = canvas.width,
        .height = canvas.height,
        .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
        .mipmaps = 1,
    };

    const texture = raylib.LoadTextureFromImage(image);
    raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));

    while (!raylib.WindowShouldClose()) {
        // TODO: don't resize window manually, make ingame buttons, check this only on button press
        const integer_scale = getIntegerScale(canvas.width, canvas.height, raylib.GetScreenWidth(), raylib.GetScreenHeight());

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.BLACK);
        raylib.DrawFPS(10, 10);

        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);
    }
}

fn getIntegerScale(width: i32, height: i32, max_width: i32, max_height: i32) f32 {
    const scale_x = @divTrunc(max_width, width);
    const scale_y = @divTrunc(max_height, height);

    return @as(f32, @floatFromInt(@min(scale_x, scale_y)));
}
