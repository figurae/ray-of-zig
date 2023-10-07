const std = @import("std");

const raylib = @import("raylib");
const config = @import("config.zig");
const t = @import("utils/types.zig");

const GfxError = error{
    DrawingOutOfBounds,
};

pub const Canvas = struct {
    const Self = @This();

    width: i32,
    height: i32,
    pixels: [config.canvas_width * config.canvas_height]raylib.Color,

    pub fn putPixel(self: *Self, pos: raylib.Vector2, color: raylib.Color) !void {
        if (isPositionOutOfBounds(pos, self.width, self.height))
            return GfxError.DrawingOutOfBounds;

        const index = t.usizeFromFloat(t.f32FromInt(self.width) * pos.y + pos.x);

        self.pixels[index] = color;
    }

    // NOTE: this should be moved to another level of abstraction
    // to allow drawing outside the screen area
    pub fn drawLine(
        self: *Self,
        from: raylib.Vector2,
        to: raylib.Vector2,
        color: raylib.Color,
    ) !void {
        const run = to.x - from.x;
        const rise = to.y - from.y;
        const slope = rise / run;
        const y_intercept = from.y - slope * from.x;

        for (t.usizeFromFloat(from.x)..(t.usizeFromFloat(to.x) + 1)) |x| {
            for (t.usizeFromFloat(from.y)..(t.usizeFromFloat(to.y) + 1)) |y| {
                const function_result = slope * t.f32FromInt(x) + y_intercept - t.f32FromInt(y);

                if (function_result < 2 and function_result > -2) {
                    try self.putPixel(.{ .x = t.f32FromInt(x), .y = t.f32FromInt(y) }, color);
                }
            }
        }
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

fn isPositionOutOfBounds(pos: raylib.Vector2, width: i32, height: i32) bool {
    return (t.i32FromFloat(pos.x) > width - 1 or t.i32FromFloat(pos.y) > height - 1);
}
