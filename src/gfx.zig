const std = @import("std");

const raylib = @import("raylib");
const config = @import("config.zig");
const bmp = @import("bmp.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub fn drawPixel(pos: raylib.Vector2, color: raylib.Color) void {
    viewport.putPixelInView(pos, color);
}

pub fn drawSprite(pos: raylib.Vector2, sprite: *const bmp.Bitmap) void {
    for (sprite.pixels, 0..) |pixel, i| {
        const i_i32: i32 = @intCast(i);
        const y = @divFloor(i_i32, sprite.width);
        const x = @rem(i_i32, sprite.width);
        // TODO: handle alpha blending
        if (pixel.a == 255) {
            drawPixel(
                .{
                    .x = t.f32FromInt(x) + pos.x,
                    .y = t.f32FromInt(y) + pos.y,
                },
                pixel,
            );
        }
    }
}

pub const canvas = struct {
    pub const width: i32 = config.canvas_width;
    pub const height: i32 = config.canvas_height;
    pub var pixels: [width * height]raylib.Color = undefined;

    fn putPixelOnCanvas(x: i32, y: i32, color: raylib.Color) void {
        const index = @as(usize, @intCast(width * y + x));
        pixels[index] = color;
    }

    pub fn clear(color: raylib.Color) void {
        for (&pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn getImage() raylib.Image {
        return .{
            .data = &pixels,
            .width = width,
            .height = height,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
            .mipmaps = 1,
        };
    }
};

pub const viewport = struct {
    var pos = raylib.Vector2{ .x = 0, .y = 0 };

    pub fn move(dir: raylib.Vector2) void {
        pos = raylib.Vector2Add(pos, dir);
    }

    fn putPixelInView(
        pixel_pos: raylib.Vector2,
        color: raylib.Color,
    ) void {
        const pos_on_canvas = raylib.Vector2Subtract(pixel_pos, pos);
        const x_on_canvas = t.i32FromFloat(@round(pos_on_canvas.x));
        const y_on_canvas = t.i32FromFloat(@round(pos_on_canvas.y));

        if (!isPixelOutOfBounds(
            x_on_canvas,
            y_on_canvas,
            canvas.width,
            canvas.height,
        )) {
            canvas.putPixelOnCanvas(x_on_canvas, y_on_canvas, color);
        }
    }
};

fn isPixelOutOfBounds(x: i32, y: i32, width: i32, height: i32) bool {
    return x < 0 or y < 0 or x >= width or y >= height;
}
