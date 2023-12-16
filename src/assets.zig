const std = @import("std");
const bmp = @import("bmp.zig");

pub const Assets = struct {
    pub var images: []bmp.Bitmap = undefined;

    pub fn init(allocator: std.mem.Allocator, image_filenames: []const []const u8) !void {
        const image_count = image_filenames.len;
        images = try allocator.alloc(bmp.Bitmap, image_count);

        for (images, 0..) |*image, i| {
            image.* = try bmp.getPixelsFromBmp(allocator, image_filenames[i]);
        }
    }

    pub fn deinit(allocator: std.mem.Allocator) void {
        for (images) |image| {
            allocator.free(image.pixels);
        }
    }
};
