const std = @import("std");

const r = @import("raylib");
const config = @import("config.zig");
const bmp = @import("bmp.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub fn drawPixel(pos: r.Vector2, color: r.Color) void {
    viewport.putPixelInView(pos, color);
}

pub fn getPixel(pos: r.Vector2) r.Color {
    return viewport.getPixelFromView(pos);
}

const DrawSpriteOptions = struct {
    dir: m.Dir = .right,
};

pub fn drawSprite(
    pos: r.Vector2,
    sprite: *const bmp.Bitmap,
    options: DrawSpriteOptions,
) void {
    for (sprite.pixels, 0..) |pixel, i| {
        const pixel_count: i32 = @intCast(sprite.pixels.len);

        var i_i32: i32 = @intCast(i);
        if (options.dir == .left or options.dir == .up)
            i_i32 = pixel_count - i_i32 - 1;

        var y = @divFloor(i_i32, sprite.width);
        var x = @rem(i_i32, sprite.width);

        if (options.dir == .down or options.dir == .up)
            std.mem.swap(i32, &x, &y);

        const pixel_pos = .{
            .x = t.f32FromInt(x) + pos.x,
            .y = t.f32FromInt(y) + pos.y,
        };

        if (pixel.a == 0) continue;

        const blended_pixel = if (pixel.a == 255) pixel else blendColors(pixel, getPixel(pixel_pos));

        drawPixel(
            pixel_pos,
            blended_pixel,
        );
    }
}

pub fn drawText(
    text: []const u8,
    pos: r.Vector2,
    font_sheet: *const bmp.Bitmap,
    color: r.Color,
) void {
    const char_offset = 32;
    const glyph_width = 4;
    const glyph_height = 7;
    const glyph_padding = 1;
    const glyphs_per_line = 31;

    for (text, 0..) |char, x| {
        const glyph_index = char - char_offset;
        const char_pos = r.Vector2Add(pos, .{ .x = t.f32FromInt(x * (glyph_width + 1)), .y = 0 });

        drawGlyph(
            char_pos,
            font_sheet,
            glyph_index,
            glyph_width,
            glyph_height,
            glyph_padding,
            glyphs_per_line,
            color,
        );
    }
}

pub const canvas = struct {
    pub const width: i32 = config.canvas_width;
    pub const height: i32 = config.canvas_height;
    pub var pixels: [width * height]r.Color = undefined;
    pub var texture: r.Texture2D = undefined;

    pub fn init() void {
        clear(r.RAYWHITE);

        const image = .{
            .data = &pixels,
            .width = width,
            .height = height,
            .format = @intFromEnum(r.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
            .mipmaps = 1,
        };
        texture = r.LoadTextureFromImage(image);
    }

    pub fn deinit() void {
        r.UnloadTexture(texture);
    }

    pub fn clear(color: r.Color) void {
        for (&pixels) |*pixel| {
            pixel.* = color;
        }
    }

    fn putPixel(x: i32, y: i32, color: r.Color) void {
        const index = getIndexFromPos(x, y, width);
        pixels[index] = color;
    }

    fn getPixel(x: i32, y: i32) r.Color {
        const index = getIndexFromPos(x, y, width);
        return pixels[index];
    }
};

pub const viewport = struct {
    var pos = r.Vector2{ .x = 0, .y = 0 };

    pub fn move(dir: r.Vector2) void {
        pos = r.Vector2Add(pos, dir);
    }

    fn putPixelInView(
        pixel_pos: r.Vector2,
        color: r.Color,
    ) void {
        const pos_on_canvas = r.Vector2Subtract(pixel_pos, pos);
        const x_on_canvas = t.i32FromFloat(@round(pos_on_canvas.x));
        const y_on_canvas = t.i32FromFloat(@round(pos_on_canvas.y));

        if (!isPixelOutOfBounds(
            x_on_canvas,
            y_on_canvas,
            canvas.width,
            canvas.height,
        )) {
            canvas.putPixel(x_on_canvas, y_on_canvas, color);
        }
    }

    fn getPixelFromView(
        pixel_pos: r.Vector2,
    ) r.Color {
        const pos_on_canvas = r.Vector2Subtract(pixel_pos, pos);
        const x_on_canvas = t.i32FromFloat(@round(pos_on_canvas.x));
        const y_on_canvas = t.i32FromFloat(@round(pos_on_canvas.y));

        if (!isPixelOutOfBounds(
            x_on_canvas,
            y_on_canvas,
            canvas.width,
            canvas.height,
        )) {
            return canvas.getPixel(x_on_canvas, y_on_canvas);
        } else {
            return r.WHITE;
        }
    }
};

// TODO: test for padding != 1
fn drawGlyph(
    pos: r.Vector2,
    font_sheet: *const bmp.Bitmap,
    glyph_index: usize,
    glyph_width: usize,
    glyph_height: usize,
    glyph_padding: usize, // assumes identical padding on all sides
    glyphs_per_line: usize,
    color: r.Color,
) void {
    const sheet_width = @as(usize, @intCast(font_sheet.width));
    const vertical_index = @divTrunc(glyph_index, glyphs_per_line);
    const horizontal_index = @mod(glyph_index, glyphs_per_line);

    const pixel_index_base = vertical_index * sheet_width * (glyph_height + glyph_padding);
    const pixel_range_base = pixel_index_base + horizontal_index * (glyph_width + 1) + glyph_padding;

    for (0..glyph_height) |y| {
        const pixel_range_start = pixel_range_base + sheet_width * (y + glyph_padding);
        const pixel_range_end = pixel_range_start + glyph_width;

        // TODO: handle additional characters
        if (pixel_range_start >= font_sheet.pixels.len) continue;

        for (font_sheet.pixels[pixel_range_start..pixel_range_end], 0..) |pixel, x| {
            // TODO: handle alpha blending
            if (pixel.a == 255) {
                canvas.putPixel(
                    @intCast(x + t.usizeFromFloat(pos.x)),
                    @intCast(y + t.usizeFromFloat(pos.y)),
                    color,
                );
            }
        }
    }
}

fn isPixelOutOfBounds(x: i32, y: i32, width: i32, height: i32) bool {
    return x < 0 or y < 0 or x >= width or y >= height;
}

fn getIndexFromPos(x: i32, y: i32, width: i32) usize {
    return @intCast(width * y + x);
}

fn blendColors(fg_color: r.Color, bg_color: r.Color) r.Color {
    const alpha = t.f64FromInt(fg_color.a) / 255.0;
    const new_r = blendChannel(fg_color.r, bg_color.r, alpha);
    const new_g = blendChannel(fg_color.g, bg_color.g, alpha);
    const new_b = blendChannel(fg_color.b, bg_color.b, alpha);

    return .{ .r = new_r, .g = new_g, .b = new_b, .a = 255 };
}

fn blendChannel(fg_channel: u8, bg_channel: u8, alpha: f64) u8 {
    const new_channel = m.lerp(t.f64FromInt(bg_channel), t.f64FromInt(fg_channel), alpha);
    return t.u8FromFloat(new_channel);
}
