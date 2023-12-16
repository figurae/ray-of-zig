const std = @import("std");
const raylib = @import("raylib");

const f = @import("utils/file.zig");

// TODO: file validation
const bmp_identifier: u16 = 0x4D42;

const BmpHeader = packed struct {
    id: u16,
    size: u32,
    reserved: u32, // actually two u16s; still, it's unused
    pixel_offset: u32,
};

// assume BITMAPV3INFOHEADER produced by Aseprite
// TODO: BITMAPINFOHEADER (size 40)
const DibHeader = packed struct {
    size: u32,
    width: i32,
    height: i32,
    planes: u16,
    bpp: u16,
    compression: u32,
    image_size: u32,
    horizontal_ppm: i32,
    vertical_ppm: i32,
    colors_used: u32,
    colors_important: u32,
    mask0: u32,
    mask1: u32,
    mask2: u32,
    mask3: u32,
};

// NOTE: it would be nice to have a deinit()
pub const Image = struct { width: i32, height: i32, pixels: []raylib.Color };

pub fn getPixelsFromBmp(allocator: std.mem.Allocator, filename: []const u8) !Image {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const reader = file.reader();
    const bmp_header = try f.readPackedStruct(reader, BmpHeader);
    const dib_header = try f.readPackedStruct(reader, DibHeader);

    std.debug.assert(bmp_header.id == bmp_identifier);

    // std.debug.print("bmp_header: {}\n", .{bmp_header});
    // std.debug.print("dib_header: {}\n", .{dib_header});

    const width: usize = @intCast(dib_header.width);
    const height: usize = @intCast(dib_header.height);

    // NOTE: workaround for buggy Aseprite 1.2.* 32-bit BMP headers
    const image_size: usize = @intCast(width * height * @divExact(dib_header.bpp, 8));

    var colors = try readColors(allocator, reader, image_size);

    const tmp: []raylib.Color = try allocator.alloc(raylib.Color, width);
    defer allocator.free(tmp);

    for (0..@as(usize, @divFloor(height, 2))) |i| {
        const i_range_start = i * width;
        const i_range_end = i_range_start + width;
        const j_range_end = colors.len - width * i;
        const j_range_start = j_range_end - width;

        const i_range = colors[i_range_start..i_range_end];
        const j_range = colors[j_range_start..j_range_end];

        @memcpy(tmp, i_range);
        @memcpy(i_range, j_range);
        @memcpy(j_range, tmp);
    }

    return .{
        .width = @intCast(width),
        .height = @intCast(height),
        .pixels = colors,
    };
}

fn readColors(allocator: std.mem.Allocator, reader: anytype, size: usize) ![]raylib.Color {
    const buffer = try allocator.alloc(u8, size);
    try reader.readNoEof(buffer);
    return std.mem.bytesAsSlice(raylib.Color, buffer);
}
