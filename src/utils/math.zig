pub fn getIntegerScale(width: i32, height: i32, max_width: i32, max_height: i32) f32 {
    const scale_x = @divTrunc(max_width, width);
    const scale_y = @divTrunc(max_height, height);

    return @as(f32, @floatFromInt(@min(scale_x, scale_y)));
}
