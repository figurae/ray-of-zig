const raylib = @import("raylib");

const config = @import("config.zig");
const gfx = @import("gfx.zig");

const m = @import("utils/math.zig");

pub const engine = struct {
    var canvas = gfx.Canvas{
        .width = config.canvas_width,
        .height = config.canvas_height,
        .pixels = [_]raylib.Color{raylib.RAYWHITE} ** (config.canvas_width * config.canvas_height),
    };

    var image: raylib.Image = undefined;
    var texture: raylib.Texture2D = undefined;

    pub fn init() void {
        raylib.SetConfigFlags(raylib.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = config.is_window_resizable });
        raylib.InitWindow(config.window_width, config.window_height, config.window_title);
        raylib.SetTargetFPS(config.target_fps);

        image = canvas.getImage();
        texture = raylib.LoadTextureFromImage(image);

        raylib.SetTextureFilter(texture, @intFromEnum(raylib.TextureFilter.TEXTURE_FILTER_POINT));
    }

    pub fn update(dt: f32) !void {
        _ = dt;
        // TODO: don't resize window manually, make ingame buttons, check this only on button press
        const integer_scale = m.getIntegerScale(canvas.width, canvas.height, raylib.GetScreenWidth(), raylib.GetScreenHeight());

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.DrawTextureEx(texture, .{ .x = 0, .y = 0 }, 0, integer_scale, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }

    pub fn deinit() void {
        raylib.UnloadTexture(texture);
        raylib.CloseWindow();
    }
};
