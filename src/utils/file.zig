const std = @import("std");

// NOTE: can the reader be typed better?
pub fn readPackedStruct(reader: anytype, comptime T: type) !T {
    comptime std.debug.assert(@typeInfo(T).Struct.layout == .Packed);
    comptime std.debug.assert(@bitSizeOf(T) % 8 == 0);

    var buffer: [@divExact(@bitSizeOf(T), 8)]u8 = undefined;
    try reader.readNoEof(&buffer);
    return @as(*align(1) T, @ptrCast(&buffer)).*;
}
