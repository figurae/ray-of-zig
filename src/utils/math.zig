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

    const ratio = t.f32FromInt(original.height) / t.f32FromInt(original.width);

    var largest_width = max.width - @mod(max.width, original.width);
    var largest_height = t.i32FromFloat(@round(t.f32FromInt(largest_width) * ratio));

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

pub const Dir = enum {
    up,
    down,
    left,
    right,
};

pub const Vector2Dir = initializeVector2Dir();

fn initializeVector2Dir() std.EnumArray(Dir, raylib.Vector2) {
    var V2D = std.EnumArray(Dir, raylib.Vector2).initUndefined();
    V2D.set(.up, raylib.Vector2{ .x = 0, .y = -1 });
    V2D.set(.down, raylib.Vector2{ .x = 0, .y = 1 });
    V2D.set(.left, raylib.Vector2{ .x = -1, .y = 0 });
    V2D.set(.right, raylib.Vector2{ .x = 1, .y = 0 });

    return V2D;
}
