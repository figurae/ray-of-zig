const std = @import("std");
const bmp = @import("bmp.zig");
const config = @import("config.zig");

pub var bitmaps: std.StringHashMap(bmp.Bitmap) = undefined;

pub fn init(allocator: std.mem.Allocator, bitmap_filenames: []const []const u8) !void {
    bitmaps = std.StringHashMap(bmp.Bitmap).init(allocator);
    for (bitmap_filenames) |filename| {
        var basename_iter = std.mem.splitSequence(u8, filename, ".");
        const basename = basename_iter.first();
        const file_path = try std.mem.join(allocator, "/", &[_][]const u8{ config.assets_dir, filename });
        try bitmaps.put(basename, try bmp.getPixelsFromBmp(allocator, file_path));
    }
}

pub fn deinit(allocator: std.mem.Allocator) void {
    var iter = bitmaps.iterator();
    while (iter.next()) |bitmap| {
        allocator.free(bitmap.value_ptr.pixels);
    }
    bitmaps.deinit();
}
