const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const snd = @import("snd.zig").Snd;
const bmp = @import("bmp.zig");
const fun = @import("fun.zig");
const primitives = @import("primitives.zig");
const assets = @import("assets.zig").Assets;

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub const Engine = struct {
    var random: std.rand.Random = undefined;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // NOTE: I think I don't have to instantiate these at all, just
    // importing these structs at the top level of this file should suffice
    var canvas: gfx.Canvas = undefined;
    var viewport: gfx.Viewport = undefined;
    var context: gfx.Context = .{
        .canvas = &canvas,
        .viewport = &viewport,
    };

    var image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;

    var dancing_lines: [10]fun.DancingLine = undefined;

    var sprite_x: f32 = 0;
    var sprite_y: f32 = 0;

    var timer: f32 = 0;
    var note: usize = 0;

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

        const target_fps = raylib.GetMonitorRefreshRate(raylib.GetCurrentMonitor());
        raylib.SetTargetFPS(target_fps);

        var pcg = std.rand.Pcg.init(@bitCast(std.time.timestamp()));
        random = pcg.random();

        canvas = gfx.Canvas{
            .width = config.canvas_width,
            .height = config.canvas_height,
            .pixels = [_]raylib.Color{raylib.RAYWHITE} ** (config.canvas_width * config.canvas_height),
        };

        try assets.init(allocator, &[_][]const u8{ "test2.bmp", "sprite.bmp" });

        viewport = gfx.Viewport{
            .pos = raylib.Vector2{ .x = 0, .y = 0 },
        };

        image = canvas.getImage();
        texture = raylib.LoadTextureFromImage(image);

        for (&dancing_lines) |*line| {
            line.* = fun.DancingLine.init(&random, null, null, null, null, null);
        }

        raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));

        try snd.init(allocator);
        try snd.addOscilator(.c_flat_2);
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

        const dir = m.Vector2Direction;

        if (raylib.IsKeyDown(.KEY_D)) viewport.move(dir.right);
        if (raylib.IsKeyDown(.KEY_A)) viewport.move(dir.left);
        if (raylib.IsKeyDown(.KEY_W)) viewport.move(dir.up);
        if (raylib.IsKeyDown(.KEY_S)) viewport.move(dir.down);

        context.canvas.clear(raylib.RAYWHITE);

        context.drawSprite(.{ .x = 0, .y = 0 }, &assets.bitmaps.get("test2").?);

        if (raylib.IsKeyDown(.KEY_RIGHT)) sprite_x += 1;
        if (raylib.IsKeyDown(.KEY_LEFT)) sprite_x -= 1;
        if (raylib.IsKeyDown(.KEY_UP)) sprite_y -= 1;
        if (raylib.IsKeyDown(.KEY_DOWN)) sprite_y += 1;

        context.drawSprite(.{ .x = sprite_x, .y = sprite_y }, &assets.bitmaps.get("sprite").?);

        for (&dancing_lines) |*line| {
            line.update(dt);
            primitives.drawLine(
                &context,
                line.pos_1,
                line.pos_2,
                line.color,
            );
        }

        raylib.UpdateTexture(texture, &canvas.pixels);
        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);

        timer += dt;

        if (timer > 0.1) {
            timer = 0;
            snd.getOscillator(0).frequency = snd.notes.get(@enumFromInt(note));
            note += 1;
        }
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        assets.deinit(allocator);

        snd.deinit();

        raylib.CloseWindow();
    }
};
