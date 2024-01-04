const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");

const t = @import("utils/types.zig");

pub fn drawLine(
    from: raylib.Vector2,
    to: raylib.Vector2,
    color: raylib.Color,
) void {
    const run = to.x - from.x;
    const rise = to.y - from.y;

    if (@abs(rise) < @abs(run)) {
        if (from.x > to.x) {
            drawLineLow(to, from, color);
        } else {
            drawLineLow(from, to, color);
        }
    } else {
        if (from.y > to.y) {
            drawLineHigh(to, from, color);
        } else {
            drawLineHigh(from, to, color);
        }
    }
}

// NOTE: this should be possible to simplify into a single function
fn drawLineLow(
    from: raylib.Vector2,
    to: raylib.Vector2,
    color: raylib.Color,
) void {
    var y_dir: f32 = 1;
    const run = to.x - from.x;
    var rise = to.y - from.y;

    if (rise < 0) {
        y_dir = -1;
        rise = -rise;
    }

    var difference = (2 * rise) - run;
    var y = from.y;

    // NOTE: it seems like this clamp has to stay... or does it?
    const from_x = std.math.clamp(from.x, 0, config.canvas_width - 1);
    const to_x = std.math.clamp(to.x, 0, config.canvas_width - 1);

    for (t.usizeFromFloat(from_x)..(t.usizeFromFloat(to_x) + 1)) |int_x| {
        const x = t.f32FromInt(int_x);

        gfx.drawPixel(.{ .x = x, .y = y }, color);

        if (difference > 0) {
            y += y_dir;
            difference += (2 * (rise - run));
        } else {
            difference += 2 * rise;
        }
    }
}

fn drawLineHigh(
    from: raylib.Vector2,
    to: raylib.Vector2,
    color: raylib.Color,
) void {
    var x_dir: f32 = 1;
    var run = to.x - from.x;
    const rise = to.y - from.y;

    if (run < 0) {
        x_dir = -1;
        run = -run;
    }

    var difference = (2 * run) - rise;
    var x = from.x;

    // NOTE: it seems like this clamp has to stay... or does it?
    const from_y = std.math.clamp(from.y, 0, config.canvas_height - 1);
    const to_y = std.math.clamp(to.y, 0, config.canvas_height - 1);

    for (t.usizeFromFloat(from_y)..(t.usizeFromFloat(to_y) + 1)) |int_y| {
        const y = t.f32FromInt(int_y);

        gfx.drawPixel(.{ .x = x, .y = y }, color);

        if (difference > 0) {
            x += x_dir;
            difference += (2 * (run - rise));
        } else {
            difference += 2 * run;
        }
    }
}
