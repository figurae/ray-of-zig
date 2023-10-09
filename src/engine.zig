const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const fun = @import("fun.zig");
const primitives = @import("primitives.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub const Engine = struct {
    var random: std.rand.Random = undefined;

    var canvas: gfx.Canvas = undefined;
    var viewport: gfx.Viewport = undefined;
    var context: gfx.Context = undefined;

    var image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;

    var dancing_lines: [100]fun.DancingLine = undefined;

    pub fn init() void {
        raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
        raylib.InitWindow(config.window_width, config.window_height, config.window_title);
        raylib.SetTargetFPS(config.target_fps);

        var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
        random = pcg.random();

        canvas = gfx.Canvas{
            .width = config.canvas_width,
            .height = config.canvas_height,
            .pixels = [_]raylib.Color{raylib.RAYWHITE} ** (config.canvas_width * config.canvas_height),
        };
        viewport = gfx.Viewport{
            .pos = raylib.Vector2{ .x = 0, .y = 0 },
        };
        context = .{
            .canvas = &canvas,
            .viewport = &viewport,
        };

        image = context.canvas.getImage();
        texture = raylib.LoadTextureFromImage(image);

        for (&dancing_lines) |*line| {
            line.* = fun.DancingLine.init(&random, null, null, null, null, null);
        }

        raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));
    }

    pub fn update(dt: f32) !void {
        // TODO: don't resize window manually, make ingame buttons, check this only on button press
        const integer_scale = m.getIntegerScale(
            context.getWidth(),
            context.getHeight(),
            raylib.GetScreenWidth(),
            raylib.GetScreenHeight(),
        );

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        // NOTE: does this have to be instantiated?
        const dir = m.Vector2Direction{};

        if (raylib.IsKeyDown(.KEY_D)) context.moveViewport(dir.right);
        if (raylib.IsKeyDown(.KEY_A)) context.moveViewport(dir.left);
        if (raylib.IsKeyDown(.KEY_W)) context.moveViewport(dir.up);
        if (raylib.IsKeyDown(.KEY_S)) context.moveViewport(dir.down);

        context.canvas.clear(raylib.RAYWHITE);

        context.viewport.putPixelInView(context.canvas, .{ .x = 30, .y = 30 }, raylib.PINK);
        primitives.drawLine(&context, .{ .x = 40, .y = 50 }, .{ .x = 120, .y = 150 }, raylib.RED);

        for (&dancing_lines) |*line| {
            line.update(dt);
            primitives.drawLine(
                &context,
                line.pos_1,
                line.pos_2,
                line.color,
            );
        }

        raylib.UpdateTexture(texture, &context.canvas.pixels);
        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        raylib.CloseWindow();
    }
};
