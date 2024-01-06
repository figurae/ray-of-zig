const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const scene_manager = @import("scene_manager.zig");

const m = @import("utils/math.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const canvas = gfx.canvas;

pub fn init() !void {
    raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
    raylib.InitWindow(config.initial_window_width, config.initial_window_height, config.window_title);

    const monitor = raylib.GetCurrentMonitor();
    const monitor_width = raylib.GetMonitorWidth(monitor);
    const monitor_height = raylib.GetMonitorHeight(monitor);
    const window_resolution = m.getNextLargestScaledResolution(
        .{
            .width = monitor_width,
            .height = monitor_height,
        },
        .{
            .width = config.canvas_width,
            .height = config.canvas_height,
        },
    );
    raylib.SetWindowSize(window_resolution.width, window_resolution.height);
    raylib.SetWindowPosition(
        @divTrunc(monitor_width - window_resolution.width, 2),
        @divTrunc(monitor_height - window_resolution.height, 2),
    );

    const target_fps = raylib.GetMonitorRefreshRate(monitor);
    raylib.SetTargetFPS(target_fps);

    canvas.init();
    raylib.SetTextureFilter(canvas.texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));

    try scene_manager.init(allocator, .snek);
}

pub fn update(dt: f32) !void {
    // TODO: don't resize window manually, make ingame buttons, check this only on button press
    const integer_scale = m.getIntegerScale(
        .{
            .width = canvas.width,
            .height = canvas.height,
        },
        .{
            .width = raylib.GetScreenWidth(),
            .height = raylib.GetScreenHeight(),
        },
    );

    raylib.BeginDrawing();
    defer raylib.EndDrawing();

    try scene_manager.update(dt);

    raylib.UpdateTexture(canvas.texture, &canvas.pixels);
    raylib.DrawTextureEx(canvas.texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);
}

pub fn deinit() void {
    scene_manager.deinit(allocator);
    canvas.deinit();
    raylib.CloseWindow();
}
