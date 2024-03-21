const std = @import("std");
const r = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const scene_manager = @import("scene_manager.zig");

const m = @import("utils/math.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const canvas = gfx.canvas;

pub fn init() !void {
    r.SetConfigFlags(r.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
    r.InitWindow(config.initial_window_width, config.initial_window_height, config.window_title);

    const monitor = r.GetCurrentMonitor();
    const monitor_width = r.GetMonitorWidth(monitor);
    const monitor_height = r.GetMonitorHeight(monitor);
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
    r.SetWindowSize(window_resolution.width, window_resolution.height);
    r.SetWindowPosition(
        @divTrunc(monitor_width - window_resolution.width, 2),
        @divTrunc(monitor_height - window_resolution.height, 2),
    );

    const target_fps = r.GetMonitorRefreshRate(monitor);
    r.SetTargetFPS(target_fps);

    canvas.init();
    r.SetTextureFilter(canvas.texture, @intFromEnum(r.TextureFilter.TEXTURE_FILTER_POINT));

    try scene_manager.init(allocator, .test_scene);
}

pub fn update(dt: f32) !void {
    // TODO: don't resize window manually, make ingame buttons, check this only on button press
    const integer_scale = m.getIntegerScale(
        .{
            .width = canvas.width,
            .height = canvas.height,
        },
        .{
            .width = r.GetScreenWidth(),
            .height = r.GetScreenHeight(),
        },
    );

    r.BeginDrawing();
    defer r.EndDrawing();

    try scene_manager.update(dt);

    r.UpdateTexture(canvas.texture, &canvas.pixels);
    r.DrawTextureEx(canvas.texture, .{ .x = 0, .y = 0 }, 0, integer_scale, r.WHITE);
}

pub fn deinit() void {
    scene_manager.deinit(allocator);
    canvas.deinit();
    r.CloseWindow();
}
