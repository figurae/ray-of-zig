const std = @import("std");
const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");
const bmp = @import("bmp.zig");
const fun = @import("fun.zig");
const primitives = @import("primitives.zig");

const m = @import("utils/math.zig");
const t = @import("utils/types.zig");

pub const Engine = struct {
    var random: std.rand.Random = undefined;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvas: gfx.Canvas = undefined;
    var viewport: gfx.Viewport = undefined;
    var context: gfx.Context = .{
        .canvas = &canvas,
        .viewport = &viewport,
    };

    var image: raylib.Image = undefined;
    var bmp_pixels: bmp.Image = undefined;
    var sprite_image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;

    var dancing_lines: [10]fun.DancingLine = undefined;

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

        bmp_pixels = try bmp.getPixelsFromBmp(allocator, "test2.bmp");
        sprite_image = .{
            .data = bmp_pixels.pixels.ptr,
            .width = bmp_pixels.width,
            .height = bmp_pixels.height,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8),
            .mipmaps = 1,
        };

        viewport = gfx.Viewport{
            .pos = raylib.Vector2{ .x = 0, .y = 0 },
        };

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

        // NOTE: does this have to be instantiated?
        const dir = m.Vector2Direction{};

        if (raylib.IsKeyDown(.KEY_D)) viewport.move(dir.right);
        if (raylib.IsKeyDown(.KEY_A)) viewport.move(dir.left);
        if (raylib.IsKeyDown(.KEY_W)) viewport.move(dir.up);
        if (raylib.IsKeyDown(.KEY_S)) viewport.move(dir.down);

        context.canvas.clear(raylib.RAYWHITE);

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

        for (bmp_pixels.pixels, 0..) |pixel, i| {
            const i_i32: i32 = @intCast(i);
            const y = @divFloor(i_i32, bmp_pixels.width);
            const x = @rem(i_i32, bmp_pixels.width);
            context.drawPixel(.{ .x = t.f32FromInt(x), .y = t.f32FromInt(y) }, pixel);
        }

        raylib.UpdateTexture(texture, &canvas.pixels);
        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        allocator.free(bmp_pixels.pixels);
        raylib.CloseWindow();
    }
};
