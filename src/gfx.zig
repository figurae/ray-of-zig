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
        const x = t.i32FromFloat(@round(pos.x));
        const y = t.i32FromFloat(@round(pos.y));

        // if (x < 0 or y < 0 or x >= self.width or y >= self.height)
        //     return GfxError.DrawingOutOfBounds;

        // NOTE: remove this bounding later, this isn't putPixel's business
        const index = @as(usize, @intCast(@abs(self.width * y + x)));
        const max_index = config.canvas_width * config.canvas_height - 1;
        const i = if (index > max_index) max_index else index;

        self.pixels[i] = color;
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

        if (@abs(rise) < @abs(run)) {
            if (from.x > to.x) {
                try self.drawLineLow(to, from, color);
            } else {
                try self.drawLineLow(from, to, color);
            }
        } else {
            if (from.y > to.y) {
                try self.drawLineHigh(to, from, color);
            } else {
                try self.drawLineHigh(from, to, color);
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

    // NOTE: this should be possible to simplify into a single function
    fn drawLineLow(
        self: *Self,
        from: raylib.Vector2,
        to: raylib.Vector2,
        color: raylib.Color,
    ) !void {
        var y_dir: f32 = 1;
        var run = to.x - from.x;
        var rise = to.y - from.y;

        if (rise < 0) {
            y_dir = -1;
            rise = -rise;
        }

        var difference = (2 * rise) - run;
        var y = from.y;

        const from_x = std.math.clamp(from.x, 0, config.canvas_width - 1);
        const to_x = std.math.clamp(to.x, 0, config.canvas_width - 1);

        for (t.usizeFromFloat(from_x)..(t.usizeFromFloat(to_x) + 1)) |int_x| {
            const x = t.f32FromInt(int_x);

            try self.putPixel(.{ .x = x, .y = y }, color);

            if (difference > 0) {
                y += y_dir;
                difference += (2 * (rise - run));
            } else {
                difference += 2 * rise;
            }
        }
    }

    fn drawLineHigh(
        self: *Self,
        from: raylib.Vector2,
        to: raylib.Vector2,
        color: raylib.Color,
    ) !void {
        var x_dir: f32 = 1;
        var run = to.x - from.x;
        var rise = to.y - from.y;

        if (run < 0) {
            x_dir = -1;
            run = -run;
        }

        var difference = (2 * run) - rise;
        var x = from.x;

        const from_y = std.math.clamp(from.y, 0, config.canvas_height - 1);
        const to_y = std.math.clamp(to.y, 0, config.canvas_height - 1);

        for (t.usizeFromFloat(from_y)..(t.usizeFromFloat(to_y) + 1)) |int_y| {
            const y = t.f32FromInt(int_y);

            try self.putPixel(.{ .x = x, .y = y }, color);

            if (difference > 0) {
                x += x_dir;
                difference += (2 * (run - rise));
            } else {
                difference += 2 * run;
            }
        }
    }
};
