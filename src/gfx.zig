const std = @import("std");

const raylib = @import("raylib");
const config = @import("config.zig");
const bmp = @import("bmp.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub fn drawPixel(pos: raylib.Vector2, color: raylib.Color) void {
    viewport.putPixelInView(pos, color);
}

pub fn drawSprite(pos: raylib.Vector2, sprite: *const bmp.Bitmap) void {
    for (sprite.pixels, 0..) |pixel, i| {
        const i_i32: i32 = @intCast(i);
        const y = @divFloor(i_i32, sprite.width);
        const x = @rem(i_i32, sprite.width);
        // TODO: handle alpha blending
        if (pixel.a == 255) {
            drawPixel(
                .{
                    .x = t.f32FromInt(x) + pos.x,
                    .y = t.f32FromInt(y) + pos.y,
                },
                pixel,
            );
        }
    }
}

pub fn drawText(
    text: []const u8,
    pos: raylib.Vector2,
    font_sheet: *const bmp.Bitmap,
    color: raylib.Color,
) void {
    const char_offset = 33;
    const glyph_width = 4;
    const glyph_height = 7;
    const glyph_padding = 1;
    const glyphs_per_line = 30;

    for (text, 0..) |char, x| {
        const glyph_index = char - char_offset;
        const char_pos = raylib.Vector2Add(pos, .{ .x = t.f32FromInt(x * (glyph_width + 1)), .y = 0 });

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
    pub var pixels: [width * height]raylib.Color = undefined;
    pub var texture: raylib.Texture2D = undefined;

    pub fn init() void {
        clear(raylib.RAYWHITE);

        const image = .{
            .data = &pixels,
            .width = width,
            .height = height,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
            .mipmaps = 1,
        };
        texture = raylib.LoadTextureFromImage(image);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
    }

    pub fn clear(color: raylib.Color) void {
        for (&pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn getImage() raylib.Image {
        return .{};
    }

    fn putPixelOnCanvas(x: i32, y: i32, color: raylib.Color) void {
        const index = @as(usize, @intCast(width * y + x));
        pixels[index] = color;
    }
};

pub const viewport = struct {
    var pos = raylib.Vector2{ .x = 0, .y = 0 };

    pub fn move(dir: raylib.Vector2) void {
        pos = raylib.Vector2Add(pos, dir);
    }

    fn putPixelInView(
        pixel_pos: raylib.Vector2,
        color: raylib.Color,
    ) void {
        const pos_on_canvas = raylib.Vector2Subtract(pixel_pos, pos);
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

// TODO: test for padding != 1
fn drawGlyph(
    pos: raylib.Vector2,
    font_sheet: *const bmp.Bitmap,
    glyph_index: usize,
    glyph_width: usize,
    glyph_height: usize,
    glyph_padding: usize, // assumes identical padding on all sides
    glyphs_per_line: usize,
    color: raylib.Color,
) void {
    const sheet_width = @as(usize, @intCast(font_sheet.width));
    const vertical_index = @divTrunc(glyph_index, glyphs_per_line);
    const horizontal_index = @mod(glyph_index, glyphs_per_line);

    const pixel_index_base = vertical_index * sheet_width * (glyph_height + glyph_padding);
    const pixel_range_base = pixel_index_base + horizontal_index * (glyph_width + 1) + glyph_padding;

    for (0..glyph_height) |y| {
        const pixel_range_start = pixel_range_base + sheet_width * (y + glyph_padding);
        const pixel_range_end = pixel_range_start + glyph_width;

        for (font_sheet.pixels[pixel_range_start..pixel_range_end], 0..) |pixel, x| {
            // TODO: handle alpha blending
            if (pixel.a == 255) {
                drawPixel(
                    .{
                        .x = t.f32FromInt(x) + pos.x,
                        .y = t.f32FromInt(y) + pos.y,
                    },
                    color,
                );
            }
        }
    }
}

fn isPixelOutOfBounds(x: i32, y: i32, width: i32, height: i32) bool {
    return x < 0 or y < 0 or x >= width or y >= height;
}
