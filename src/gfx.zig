const std = @import("std");

const raylib = @import("raylib");
const config = @import("config.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

const GfxError = error{
    DrawingOutOfBounds,
};

pub const Context = struct {
    const Self = @This();

    canvas: *Canvas,
    viewport: *Viewport,

    pub fn drawPixel(self: *Self, pos: raylib.Vector2, color: raylib.Color) !void {
        try self.viewport.putPixelInView(self.canvas, pos, color);
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

    pub fn putPixelOnCanvas(self: *Self, pos: raylib.Vector2, color: raylib.Color) !void {
        const x = t.i32FromFloat(@round(pos.x));
        const y = t.i32FromFloat(@round(pos.y));

        if (isPixelOutOfBounds(x, y, self.width, self.height))
            return GfxError.DrawingOutOfBounds;

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
    ) !void {
        const actual_pos = raylib.Vector2Subtract(pixel_pos, self.pos);

        if (!isPixelOutOfBounds(
            t.i32FromFloat(@round(actual_pos.x)),
            t.i32FromFloat(@round(actual_pos.y)),
            canvas.width,
            canvas.height,
        )) {
            try canvas.putPixelOnCanvas(actual_pos, color);
        }
    }
};

fn isPixelOutOfBounds(x: i32, y: i32, width: i32, height: i32) bool {
    const isPixelOob = x < 0 or y < 0 or x >= width or y >= height;
    return isPixelOob;
}
