const std = @import("std");
const raylib = @import("raylib");

const t = @import("./types.zig");

const Resolution = struct {
    width: i32,
    height: i32,
};

pub fn getIntegerScale(canvas: Resolution, max: Resolution) f32 {
    const scale_x = @divTrunc(max.width, canvas.width);
    const scale_y = @divTrunc(max.height, canvas.height);

    return @as(f32, @floatFromInt(@min(scale_x, scale_y)));
}

pub fn getNextLargestScaledResolution(
    max: Resolution,
    original: Resolution,
) Resolution {
    std.debug.assert(max.width > 0 and
        max.height > 0 and
        original.width > 0 and
        original.height > 0);

    const ratio = t.f32FromInt(original.width) / t.f32FromInt(original.height);

    var largest_height = max.height - @mod(max.height, original.height);
    var largest_width = t.i32FromFloat(@round(t.f32FromInt(largest_height) * ratio));

    // NOTE: this is for screens with weird aspect ratios
    while (largest_height >= max.height or largest_width >= max.width) {
        largest_height -= original.height;
        largest_width -= original.width;
    }

    return .{
        .width = largest_width,
        .height = largest_height,
    };
}

pub const Vector2Direction = struct {
    up: raylib.Vector2 = .{ .x = 0, .y = -1 },
    down: raylib.Vector2 = .{ .x = 0, .y = 1 },
    left: raylib.Vector2 = .{ .x = -1, .y = 0 },
    right: raylib.Vector2 = .{ .x = 1, .y = 0 },
};
