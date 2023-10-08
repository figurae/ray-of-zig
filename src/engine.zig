const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const fun = @import("fun.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

const Viewport = struct {
    pos: raylib.Vector2,
    width: i32,
    height: i32,
};

pub const Engine = struct {
    var canvas = gfx.Canvas{
        .width = config.canvas_width,
        .height = config.canvas_height,
        .pixels = [_]raylib.Color{raylib.RAYWHITE} ** (config.canvas_width * config.canvas_height),
    };
    var viewport = Viewport{
        .pos = raylib.Vector2{ .x = 0, .y = 0 },
        .width = config.canvas_width,
        .height = config.canvas_height,
    };

    var random: std.rand.Random = undefined;
    var image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;
    var dancing_lines: [100]fun.DancingLine = undefined;

    pub fn init() void {
        raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
        raylib.InitWindow(config.window_width, config.window_height, config.window_title);
        raylib.SetTargetFPS(config.target_fps);

        var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
        random = pcg.random();
        image = canvas.getImage();
        texture = raylib.LoadTextureFromImage(image);
        for (&dancing_lines) |*line| {
            line.* = fun.DancingLine.init(&random, null, null, null, null, null);
        }

        raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));
    }

    pub fn update(dt: f32) !void {
        // TODO: don't resize window manually, make ingame buttons, check this only on button press
        const integer_scale = m.getIntegerScale(
            canvas.width,
            canvas.height,
            raylib.GetScreenWidth(),
            raylib.GetScreenHeight(),
        );

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        if (raylib.IsKeyDown(.KEY_D)) viewport.pos.x += 1;
        if (raylib.IsKeyDown(.KEY_A)) viewport.pos.x -= 1;
        if (raylib.IsKeyDown(.KEY_W)) viewport.pos.y -= 1;
        if (raylib.IsKeyDown(.KEY_S)) viewport.pos.y += 1;

        canvas.clear(raylib.RAYWHITE);

        for (&dancing_lines) |*line| {
            line.update(dt);
            try canvas.drawLine(raylib.Vector2Add(line.pos_1, viewport.pos), raylib.Vector2Add(line.pos_2, viewport.pos), line.color);
        }

        raylib.UpdateTexture(texture, &canvas.pixels);
        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        raylib.CloseWindow();
    }
};
