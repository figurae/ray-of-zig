const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub const engine = struct {
    var canvas = gfx.Canvas{
        .width = config.canvas_width,
        .height = config.canvas_height,
        .pixels = [_]raylib.Color{raylib.RAYWHITE} ** (config.canvas_width * config.canvas_height),
    };

    var image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;
    const pos1 = .{ .x = t.f32FromInt(config.canvas_width) / 2 - 1, .y = t.f32FromInt(config.canvas_height) / 2 - 1 };
    var pos2: raylib.Vector2 = undefined;
    const angular_speed: f32 = 3;
    var angle: f32 = 2;
    const radius: f32 = 50;

    pub fn init() void {
        raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
        raylib.InitWindow(config.window_width, config.window_height, config.window_title);
        raylib.SetTargetFPS(config.target_fps);

        image = canvas.getImage();
        texture = raylib.LoadTextureFromImage(image);

        raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));
    }

    pub fn update(dt: f32) !void {
        // TODO: don't resize window manually, make ingame buttons, check this only on button press
        const integer_scale = m.getIntegerScale(canvas.width, canvas.height, raylib.GetScreenWidth(), raylib.GetScreenHeight());

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        canvas.clear(raylib.RAYWHITE);

        angle += angular_speed * dt;
        pos2 = .{
            .x = @round(radius * @cos(angle) + pos1.x),
            .y = @round(radius * @sin(angle) + pos1.y),
        };

        try canvas.drawLine(pos1, pos2, raylib.RED);

        raylib.UpdateTexture(texture, &canvas.pixels);
        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        raylib.CloseWindow();
    }
};
