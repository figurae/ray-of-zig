const std = @import("std");
const r = @import("raylib");

const a4_frequency = 440;

const sample_rate = 48000;
const default_amplitude = 0.2;
const max_samples_per_update: i32 = 4096;

var frequencies: std.EnumArray(Note, f32) = undefined;
var oscillators: std.ArrayList(Oscillator) = undefined;
var stream: r.AudioStream = undefined;
var envelope: Envelope = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    oscillators = std.ArrayList(Oscillator).init(allocator);
    envelope = Envelope.init(.{});
    frequencies = generateFrequencies();

    r.InitAudioDevice();

    r.SetAudioStreamBufferSizeDefault(max_samples_per_update);
    stream = r.LoadAudioStream(@intFromFloat(sample_rate), 16, 1);
    r.SetAudioStreamCallback(stream, audio_callback);
    r.PlayAudioStream(stream);
}

pub fn deinit() void {
    r.UnloadAudioStream(stream);
    r.CloseAudioDevice();

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

fn generateFrequencies() std.EnumArray(Note, f32) {
    var freq = std.EnumArray(Note, f32).initUndefined();

    const semitone_ratio = std.math.pow(f64, 2, 1.0 / 12.0);
    const a4_position = 57;

    for (0..freq.values.len) |i| {
        const power = @as(i32, @intCast(i)) - a4_position;
        const note_frequency = a4_frequency * std.math.pow(f64, semitone_ratio, @floatFromInt(power));
        const note_name: Note = @enumFromInt(i);

        freq.set(note_name, @floatCast(note_frequency));
    }

    return freq;
}

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

    pub fn play(self: *Self, note: Note) void {
        // NOTE: a global again... maybe create a sound context of some kind?
        envelope.reset();
        self.current_note = note;
        self.frequency = frequencies.get(note);
    }
};

const Envelope = struct {
    const Self = @This();

    attack_time: f32,
    attack_sample_count: f32,
    attack_step: f32,

    decay_time: f32,
    decay_sample_count: f32,
    decay_step: f32,

    release_time: f32,
    release_sample_count: f32,
    release_step: f32,

    amplitude_start: f32,
    amplitude_max: f32,
    amplitude_sustain: f32,
    amplitude_end: f32,

    current_output: f32,

    const EnvConfig = struct {
        attack_time: f32 = 0.001,
        decay_time: f32 = 0.15,
        release_time: f32 = 0.2,
        amplitude_start: f32 = 0,
        amplitude_max: f32 = default_amplitude,
        amplitude_sustain: f32 = std.math.clamp(default_amplitude - 1, 0, 1),
        amplitude_end: f32 = 0,
    };

    fn init(env_config: EnvConfig) Self {
        const attack_sample_count = calculateSamples(env_config.attack_time);
        const attack_step = 1 / attack_sample_count * (env_config.amplitude_max - env_config.amplitude_start);
        const decay_sample_count = calculateSamples(env_config.decay_time);
        const decay_step = 1 / decay_sample_count * (env_config.amplitude_sustain - env_config.amplitude_max);
        const release_sample_count = calculateSamples(env_config.release_time);
        const release_step = 1 / release_sample_count * (env_config.amplitude_end - env_config.amplitude_sustain);

        return .{
            .attack_time = env_config.attack_time,
            .attack_sample_count = attack_sample_count,
            .attack_step = attack_step,
            .decay_time = env_config.decay_time,
            .decay_sample_count = decay_sample_count,
            .decay_step = decay_step,
            .release_time = env_config.release_time,
            .release_sample_count = release_sample_count,
            .release_step = release_step,
            .amplitude_start = env_config.amplitude_start,
            .amplitude_max = env_config.amplitude_max,
            .amplitude_sustain = env_config.amplitude_sustain,
            .amplitude_end = env_config.amplitude_end,
            .current_output = env_config.amplitude_start,
        };
    }

    fn reset(self: *Self) void {
        self.attack_sample_count = calculateSamples(self.attack_time);
        self.decay_sample_count = calculateSamples(self.decay_time);
        self.release_sample_count = calculateSamples(self.release_time);
        self.current_output = self.amplitude_start;
    }

    fn next(self: *Self) f32 {
        if (self.attack_sample_count > 0) {
            self.current_output += self.attack_step;
            self.attack_sample_count -= 1;
        } else if (self.decay_sample_count > 0) {
            self.current_output += self.decay_step;
            self.decay_sample_count -= 1;
            // TODO: implement sustain
        } else if (self.release_sample_count > 0) {
            self.current_output += self.release_step;
            self.release_sample_count -= 1;
        } else {
            self.current_output = self.amplitude_end;
        }

        return std.math.clamp(self.current_output, 0, 1);
    }

    fn calculateSamples(time: f32) f32 {
        const samples = @round(time * sample_rate);
        return if (samples > 0) samples else 1;
    }
};

// NOTE: ideally, I'd want this to be both a separate file
// and top-level, but it doesn't seem possible like with structs
pub const Note = enum {
    c_flat_0,
    c_sharp_0,
    d_flat_0,
    d_sharp_0,
    e_flat_0,
    f_flat_0,
    f_sharp_0,
    g_flat_0,
    g_sharp_0,
    a_flat_0,
    a_sharp_0,
    b_flat_0,
    c_flat_1,
    c_sharp_1,
    d_flat_1,
    d_sharp_1,
    e_flat_1,
    f_flat_1,
    f_sharp_1,
    g_flat_1,
    g_sharp_1,
    a_flat_1,
    a_sharp_1,
    b_flat_1,
    c_flat_2,
    c_sharp_2,
    d_flat_2,
    d_sharp_2,
    e_flat_2,
    f_flat_2,
    f_sharp_2,
    g_flat_2,
    g_sharp_2,
    a_flat_2,
    a_sharp_2,
    b_flat_2,
    c_flat_3,
    c_sharp_3,
    d_flat_3,
    d_sharp_3,
    e_flat_3,
    f_flat_3,
    f_sharp_3,
    g_flat_3,
    g_sharp_3,
    a_flat_3,
    a_sharp_3,
    b_flat_3,
    c_flat_4,
    c_sharp_4,
    d_flat_4,
    d_sharp_4,
    e_flat_4,
    f_flat_4,
    f_sharp_4,
    g_flat_4,
    g_sharp_4,
    a_flat_4,
    a_sharp_4,
    b_flat_4,
    c_flat_5,
    c_sharp_5,
    d_flat_5,
    d_sharp_5,
    e_flat_5,
    f_flat_5,
    f_sharp_5,
    g_flat_5,
    g_sharp_5,
    a_flat_5,
    a_sharp_5,
    b_flat_5,
    c_flat_6,
    c_sharp_6,
    d_flat_6,
    d_sharp_6,
    e_flat_6,
    f_flat_6,
    f_sharp_6,
    g_flat_6,
    g_sharp_6,
    a_flat_6,
    a_sharp_6,
    b_flat_6,
    c_flat_7,
    c_sharp_7,
    d_flat_7,
    d_sharp_7,
    e_flat_7,
    f_flat_7,
    f_sharp_7,
    g_flat_7,
    g_sharp_7,
    a_flat_7,
    a_sharp_7,
    b_flat_7,
    c_flat_8,
    c_sharp_8,
    d_flat_8,
    d_sharp_8,
    e_flat_8,
    f_flat_8,
    f_sharp_8,
    g_flat_8,
    g_sharp_8,
    a_flat_8,
    a_sharp_8,
    b_flat_8,
};
