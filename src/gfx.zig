const std = @import("std");

const raylib = @import("raylib");
const config = @import("config.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub const Context = struct {
    const Self = @This();

    canvas: *Canvas,
    viewport: *Viewport,

    pub fn drawPixel(self: *Self, pos: raylib.Vector2, color: raylib.Color) void {
        self.viewport.putPixelInView(self.canvas, pos, color);
    }

    pub fn moveViewport(self: *Self, dir: raylib.Vector2) void {
        self.viewport.pos = raylib.Vector2Add(self.viewport.pos, dir);
    }

    pub fn getWidth(self: *const Self) i32 {
        return self.canvas.width;
    }

    pub fn getHeight(self: *const Self) i32 {
        return self.canvas.height;
    }
};

pub const Canvas = struct {
    const Self = @This();

    width: i32,
    height: i32,
    pixels: [config.canvas_width * config.canvas_height]raylib.Color,

    pub fn putPixelOnCanvas(self: *Self, x: i32, y: i32, color: raylib.Color) void {
        const index = @as(usize, @intCast(self.width * y + x));
        self.pixels[index] = color;
    }

    pub fn clear(self: *Self, color: raylib.Color) void {
        for (&self.pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn getImage(self: *Self) raylib.Image {
        return .{
            .data = &self.pixels,
            .width = self.width,
            .height = self.height,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
            .mipmaps = 1,
        };
    }
};

pub const Viewport = struct {
    pos: raylib.Vector2,

    pub fn putPixelInView(
        self: *const Viewport,
        canvas: *Canvas,
        pixel_pos: raylib.Vector2,
        color: raylib.Color,
    ) void {
        const pos_on_canvas = raylib.Vector2Subtract(pixel_pos, self.pos);
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
    const isPixelOob = x < 0 or y < 0 or x >= width or y >= height;
    return isPixelOob;
}
