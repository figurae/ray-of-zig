const raylib = @import("raylib");
const config = @import("config.zig");
const t = @import("utils/types.zig");

const Error = error{
    PixelOutOfBounds,
};

pub const Canvas = struct {
    const Self = @This();

    width: i32,
    height: i32,
    pixels: [config.canvas_width * config.canvas_height]raylib.Color,

    pub fn putPixel(self: *Self, pos: raylib.Vector2, color: raylib.Color) !void {
        if (t.i32FromFloat(pos.x) > self.width - 1 or t.i32FromFloat(pos.y) > self.height - 1) {
            return Error.PixelOutOfBounds;
        }

        const index = t.usizeFromFloat(t.f32FromInt(self.width) * pos.y + pos.x);

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
