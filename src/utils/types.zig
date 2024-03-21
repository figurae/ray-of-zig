// NOTE: can this be made a bit more generic while maintaining runtime usability?
pub fn i32FromFloat(float: anytype) i32 {
    return @as(i32, @intFromFloat(float));
}

pub fn u8FromFloat(float: anytype) u8 {
    return @as(u8, @intFromFloat(float));
}

pub fn usizeFromFloat(float: anytype) usize {
    return @as(usize, @intFromFloat(float));
}

pub fn f32FromInt(int: anytype) f32 {
    return @as(f32, @floatFromInt(int));
}

pub fn f64FromInt(int: anytype) f64 {
    return @as(f64, @floatFromInt(int));
}
