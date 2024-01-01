const std = @import("std");

const raylib = @import("raylib");
const Note = @import("note.zig").Note;

const a4_frequency = 440;

pub const Snd = struct {
    const sample_rate = 48000;
    const default_amplitude = 0.2;
    const max_samples_per_update: i32 = 4096;

    pub var frequencies: std.EnumArray(Note, f32) = undefined;
    var oscillators: std.ArrayList(Oscillator) = undefined;
    var stream: raylib.AudioStream = undefined;
    // TODO: don't pub this, make an interface
    pub var envelope: Envelope = undefined;

    const Oscillator = struct {
        const Self = @This();

        current_note: Note,
        current_step: f32,
        frequency: f32,
        amplitude: f32,

        fn init(initial_note: Note, amplitude: f32) Self {
            return .{
                .current_step = 0,
                .current_note = initial_note,
                .frequency = frequencies.get(initial_note),
                .amplitude = amplitude,
            };
        }

        fn next(self: *Self) f32 {
            const current_value = @sin(self.current_step * 2 * std.math.pi);

            self.current_step += self.frequency / sample_rate;
            if (self.current_step > 1) self.current_step -= 1;

            return current_value * self.amplitude;
        }
    };

    const Envelope = struct {
        const Self = @This();

        attack_time: f32,
        attack_samples: f32,
        attack_step: f32,

        decay_time: f32,
        decay_samples: f32,
        decay_step: f32,

        release_time: f32,
        release_samples: f32,
        release_step: f32,

        amplitude_start: f32,
        amplitude_max: f32,
        amplitude_sustain: f32,
        amplitude_end: f32,

        current_output: f32,

        // NOTE: a configuration tuple should be more elegant
        fn init(
            attack_time: f32,
            decay_time: f32,
            release_time: f32,
            amplitude_start: f32,
            amplitude_max: f32,
            amplitude_sustain: f32,
            amplitude_end: f32,
        ) Self {
            const attack_samples = attack_time * sample_rate;
            const attack_step = 1 / attack_samples * @abs(amplitude_max - amplitude_start);
            const decay_samples = decay_time * sample_rate;
            const decay_step = 1 / decay_samples * @abs(amplitude_max - amplitude_sustain);
            const release_samples = release_time * sample_rate;
            const release_step = 1 / release_samples * @abs(amplitude_sustain - amplitude_end);

            return .{
                .attack_time = attack_time,
                .attack_samples = attack_samples,
                .attack_step = attack_step,
                .decay_time = decay_time,
                .decay_samples = decay_samples,
                .decay_step = decay_step,
                .release_time = release_time,
                .release_samples = release_samples,
                .release_step = release_step,
                .amplitude_start = amplitude_start,
                .amplitude_max = amplitude_max,
                .amplitude_sustain = amplitude_sustain,
                .amplitude_end = amplitude_end,
                .current_output = amplitude_start,
            };
        }

        // TODO: don't pub this, make an interface
        pub fn reset(self: *Self) void {
            self.attack_samples = self.attack_time * sample_rate;
            self.decay_samples = self.decay_time * sample_rate;
            self.release_samples = self.release_time * sample_rate;
        }

        fn next(self: *Self) f32 {
            if (self.attack_samples > 0) {
                self.current_output += self.attack_step;
                self.attack_samples -= 1;
            } else if (self.decay_samples > 0) {
                self.current_output -= self.decay_step;
                self.decay_samples -= 1;
                // TODO: implement sustain
            } else if (self.release_samples > 0) {
                self.current_output -= self.release_step;
                self.release_samples -= 1;
            } else {
                self.current_output = self.amplitude_end;
            }

            return self.current_output;
        }
    };

    // NOTE: how to do this without globals?
    fn audio_callback(any_buffer: ?*anyopaque, frames: u32) void {
        const buffer: []c_short = @as([*]c_short, @ptrCast(@alignCast(any_buffer.?)))[0..frames];

        for (buffer) |*sample| {
            var mixedSample: f32 = 0;
            for (oscillators.items) |*oscillator| {
                mixedSample += oscillator.*.next();
            }

            if (mixedSample != 0) {
                const clampedSample = std.math.clamp(mixedSample * envelope.next(), -1.0, 1.0);
                sample.* = @intFromFloat(clampedSample * 32000);
            }
        }
    }

    pub fn init(allocator: std.mem.Allocator) !void {
        oscillators = std.ArrayList(Oscillator).init(allocator);
        envelope = Envelope.init(0.05, 0.2, 0.2, 0, 0.4, 0.5, 0);
        frequencies = generateFrequencies();

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
            initial_note,
            default_amplitude,
        ));
    }

    pub fn getOscillator(index: usize) *Oscillator {
        return &oscillators.items[index];
    }
};

fn generateFrequencies() std.EnumArray(Note, f32) {
    var frequencies = std.EnumArray(Note, f32).initUndefined();

    const semitone_ratio = std.math.pow(f64, 2, 1.0 / 12.0);
    const a4_position = 57;

    for (0..frequencies.values.len) |i| {
        const power = @as(i32, @intCast(i)) - a4_position;
        const note_frequency = a4_frequency * std.math.pow(f64, semitone_ratio, @floatFromInt(power));
        const note_name: Note = @enumFromInt(i);

        frequencies.set(note_name, @floatCast(note_frequency));
    }

    return frequencies;
}
