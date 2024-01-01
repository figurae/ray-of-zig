const std = @import("std");

const raylib = @import("raylib");
const Note = @import("note.zig").Note;

const t = @import("utils/types.zig");

const a4_frequency = 440;

pub const Snd = struct {
    const sample_rate = 48000;
    const amplitude = 0.2;
    const max_samples_per_update: i32 = 4096;

    pub var notes: std.EnumArray(Note, f32) = undefined;
    var oscillators: std.ArrayList(Oscillator) = undefined;
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

        notes = generateNotes();

        raylib.InitAudioDevice();

        raylib.SetAudioStreamBufferSizeDefault(max_samples_per_update);
        stream = raylib.LoadAudioStream(@intFromFloat(sample_rate), 16, 1);

        raylib.SetAudioStreamCallback(stream, audio_callback);
        raylib.PlayAudioStream(stream);
    }

    pub fn deinit() void {
        raylib.UnloadAudioStream(stream);
        raylib.CloseAudioDevice();

        oscillators.deinit();
    }

    pub fn addOscilator(initial_note: Note) !void {
        try oscillators.append(Oscillator.init(
            notes.get(initial_note),
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

fn generateNotes() std.EnumArray(Note, f32) {
    var notes = std.EnumArray(Note, f32).initUndefined();

    const semitone_ratio = std.math.pow(f64, 2, 1.0 / 12.0);
    const note_count = 108;
    const a4_position = 57;

    for (0..note_count) |i| {
        const power = @as(i32, @intCast(i)) - a4_position;
        const note_frequency = a4_frequency * std.math.pow(f64, semitone_ratio, t.f32FromInt(power));
        const note_name: Note = @enumFromInt(i);

        notes.set(note_name, @floatCast(note_frequency));
    }

    return notes;
}
