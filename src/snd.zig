const std = @import("std");

const raylib = @import("raylib");

const t = @import("utils/types.zig");

const a4_frequency = 440;

pub const Snd = struct {
    const sample_rate = 48000;
    const amplitude = 0.2;
    const max_samples_per_update: i32 = 4096;

    var oscillators: std.ArrayList(Oscillator) = undefined;
    var notes: std.StringHashMap(f32) = undefined;
    var stream: raylib.AudioStream = undefined;

    fn audio_callback(any_buffer: ?*anyopaque, frames: u32) void {
        const buffer: []c_short = @as([*]c_short, @ptrCast(@alignCast(any_buffer.?)))[0..frames];

        for (buffer) |*sample| {
            if (oscillators.items.len > 0) {
                sample.* = @intFromFloat(oscillators.items[0].next() * 32000);
            }
        }
    }

    pub fn init(allocator: std.mem.Allocator) !void {
        oscillators = std.ArrayList(Oscillator).init(allocator);

        notes = try generateNotes(allocator);

        raylib.InitAudioDevice();

        raylib.SetAudioStreamBufferSizeDefault(max_samples_per_update);
        stream = raylib.LoadAudioStream(@intFromFloat(sample_rate), 16, 1);

        raylib.SetAudioStreamCallback(stream, audio_callback);
        raylib.PlayAudioStream(stream);
    }

    pub fn deinit(allocator: std.mem.Allocator) void {
        raylib.UnloadAudioStream(stream);
        raylib.CloseAudioDevice();

        var iter = notes.keyIterator();
        while (iter.next()) |key| {
            allocator.free(key.*);
        }
        notes.deinit();

        oscillators.deinit();
    }

    pub fn addOscilator(initial_note: []const u8) !void {
        try oscillators.append(Oscillator.init(
            notes.get(initial_note) orelse a4_frequency,
            sample_rate,
            amplitude,
        ));
    }

    pub fn getOscillator(index: usize) *Oscillator {
        return &oscillators.items[index];
    }
};

const Oscillator = struct {
    const Self = @This();

    current_step: f32,
    frequency: f32,
    sample_rate: f32,
    amplitude: f32,

    fn init(frequency: f32, sample_rate: f32, amplitude: f32) Self {
        return .{
            .current_step = 0,
            .frequency = frequency,
            .sample_rate = sample_rate,
            .amplitude = amplitude,
        };
    }

    fn next(self: *Self) f32 {
        const current_value = @sin(self.current_step * 2 * std.math.pi);

        self.current_step += self.frequency / self.sample_rate;
        if (self.current_step > 1) self.current_step -= 1;

        return current_value;
    }
};

fn generateNotes(allocator: std.mem.Allocator) !std.StringHashMap(f32) {
    const semitone_ratio = std.math.pow(f64, 2, 1.0 / 12.0);
    var notes = std.StringHashMap(f32).init(allocator);

    const note_count = 108;
    const a4_position = 57;
    const note_names = [_][]const u8{ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };

    for (0..note_count) |i| {
        const power = @as(i32, @intCast(i)) - a4_position;
        const note_frequency = a4_frequency * std.math.pow(f64, semitone_ratio, t.f32FromInt(power));
        const octave = @divFloor(i, 12);
        const note_index = @mod(i, 12);
        const note_name = note_names[note_index];

        // NOTE: is this possible to do without an allocator? bufPrint fails
        const full_note_name = try std.fmt.allocPrint(allocator, "{s}{d}", .{ note_name, octave });
        try notes.put(full_note_name, @floatCast(note_frequency));
    }

    return notes;
}
