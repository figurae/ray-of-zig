const std = @import("std");
const scene_index = @import("scenes/index.zig");

const SceneName = enum {
    test_scene,
    snek,
};

const Scene = struct {
    init: *const fn (allocator: std.mem.Allocator) anyerror!void,
    deinit: *const fn (allocator: std.mem.Allocator) void,
    update: *const fn (dt: f32) anyerror!void,
};

var current_scene: SceneName = undefined;
var scenes: std.EnumArray(SceneName, Scene) = generateScenes();

pub fn init(allocator: std.mem.Allocator, scene_name: SceneName) !void {
    current_scene = scene_name;
    try scenes.get(current_scene).init(allocator);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    scenes.get(current_scene).deinit(allocator);
}

pub fn update(dt: f32) !void {
    try scenes.get(current_scene).update(dt);
}

fn generateScenes() std.EnumArray(SceneName, Scene) {
    var s = std.EnumArray(SceneName, Scene).initUndefined();

    inline for (@typeInfo(scene_index).Struct.decls, 0..) |decl, i| {
        const scene: Scene = .{
            .init = @field(scene_index, decl.name).init,
            .deinit = @field(scene_index, decl.name).deinit,
            .update = @field(scene_index, decl.name).update,
        };
        s.set(@enumFromInt(i), scene);
    }

    return s;
}
