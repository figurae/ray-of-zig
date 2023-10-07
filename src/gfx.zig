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

        if (@abs(rise) < @abs(run)) {
            if (from.x > to.x) {
                try self.drawLineLow(to, from, run, rise, color);
            } else {
                try self.drawLineLow(from, to, run, rise, color);
            }
        } else {
            if (from.y > to.y) {
                try self.drawLineHigh(to, from, run, rise, color);
            } else {
                try self.drawLineHigh(from, to, run, rise, color);
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
        run: f32,
        original_rise: f32,
        color: raylib.Color,
    ) !void {
        var y_dir: f32 = 1;
        var rise = original_rise;

        if (rise < 0) {
            y_dir = -1;
            rise = -rise;
        }

        var difference = (2 * rise) - run;
        var y = from.y;

        for (t.usizeFromFloat(from.x)..(t.usizeFromFloat(to.x) + 1)) |int_x| {
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
        original_run: f32,
        rise: f32,
        color: raylib.Color,
    ) !void {
        var x_dir: f32 = 1;
        var run = original_run;

        if (run < 0) {
            x_dir = -1;
            run = -run;
        }

        var difference = (2 * run) - rise;
        var x = from.x;

        for (t.usizeFromFloat(from.y)..(t.usizeFromFloat(to.y) + 1)) |int_y| {
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

    fn isPositionOutOfBounds(pos: raylib.Vector2, width: i32, height: i32) bool {
        return (t.i32FromFloat(pos.x) > width - 1 or t.i32FromFloat(pos.y) > height - 1);
    }
};
