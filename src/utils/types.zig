const std = @import("std");

pub fn i32FromFloat(float: anytype) i32 {
    return @as(i32, @intFromFloat(float));
}
