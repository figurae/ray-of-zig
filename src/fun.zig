const std = @import("std");
const raylib = @import("raylib");
const config = @import("config.zig");

pub const DancingLine = struct {
    const Self = @This();
    const max_vel: f32 = 100;

    pos_1: raylib.Vector2,
    vel_1: raylib.Vector2,

    pos_2: raylib.Vector2,
    vel_2: raylib.Vector2,

    color: raylib.Color,

    pub fn init(
        random: *std.rand.Random,
        pos_1_arg: ?raylib.Vector2,
        vel_1_arg: ?raylib.Vector2,
        pos_2_arg: ?raylib.Vector2,
        vel_2_arg: ?raylib.Vector2,
        color_arg: ?raylib.Color,
    ) Self {
        const pos_1 = if (pos_1_arg) |pos| pos else raylib.Vector2{
            .x = random.float(f32) * (config.canvas_width - 1),
            .y = random.float(f32) * (config.canvas_height - 1),
        };
        const vel_1 = if (vel_1_arg) |vel| vel else raylib.Vector2{
            .x = random.float(f32) * max_vel,
            .y = random.float(f32) * max_vel,
        };
        const pos_2 = if (pos_2_arg) |pos| pos else raylib.Vector2{
            .x = random.float(f32) * (config.canvas_width - 1),
            .y = random.float(f32) * (config.canvas_height - 1),
        };
        const vel_2 = if (vel_2_arg) |pos| pos else raylib.Vector2{
            .x = random.float(f32) * max_vel,
            .y = random.float(f32) * max_vel,
        };
        const color = if (color_arg) |col| col else getRandomColor(random);

        return .{
            .pos_1 = pos_1,
            .vel_1 = vel_1,
            .pos_2 = pos_2,
            .vel_2 = vel_2,
            .color = color,
        };
    }

    pub fn update(self: *Self, dt: f32) void {
        var next_x_1 = self.pos_1.x + self.vel_1.x * dt;
        var next_y_1 = self.pos_1.y + self.vel_1.y * dt;
        var next_x_2 = self.pos_2.x + self.vel_2.x * dt;
        var next_y_2 = self.pos_2.y + self.vel_2.y * dt;

        if (next_x_1 < 0 or next_x_1 >= config.canvas_width - 1) {
            next_x_1 -= 2 * (self.vel_1.x * dt);
            self.vel_1.x *= -1;
        }

        if (next_y_1 < 0 or next_y_1 >= config.canvas_height - 1) {
            next_y_1 -= 2 * (self.vel_1.y * dt);
            self.vel_1.y *= -1;
        }

        if (next_x_2 < 0 or next_x_2 >= config.canvas_width - 1) {
            next_x_2 -= 2 * (self.vel_2.x * dt);
            self.vel_2.x *= -1;
        }

        if (next_y_2 < 0 or next_y_2 >= config.canvas_height - 1) {
            next_y_2 -= 2 * (self.vel_2.y * dt);
            self.vel_2.y *= -1;
        }

        self.pos_1.x = next_x_1;
        self.pos_1.y = next_y_1;
        self.pos_2.x = next_x_2;
        self.pos_2.y = next_y_2;
    }
};

fn getRandomColor(random: *std.rand.Random) raylib.Color {
    return .{
        .r = random.int(u8),
        .g = random.int(u8),
        .b = random.int(u8),
        .a = 255,
    };
}
