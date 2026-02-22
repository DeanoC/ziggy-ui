const std = @import("std");

var reduced_motion_enabled: bool = false;

pub const Easing = enum {
    linear,
    ease_in,
    ease_out,
    ease_in_out,
};

pub const AnimationTrack = struct {
    id: u64,
    from: f32,
    to: f32,
    value: f32,
    duration: f32,
    elapsed: f32 = 0.0,
    easing: Easing = .ease_in_out,
    playing: bool = true,
};

pub const Animator = struct {
    allocator: std.mem.Allocator,
    tracks: std.AutoHashMap(u64, AnimationTrack),

    pub fn init(allocator: std.mem.Allocator) Animator {
        return .{
            .allocator = allocator,
            .tracks = std.AutoHashMap(u64, AnimationTrack).init(allocator),
        };
    }

    pub fn deinit(self: *Animator) void {
        self.tracks.deinit();
    }

    pub fn clear(self: *Animator) void {
        self.tracks.clearRetainingCapacity();
    }

    pub fn start(self: *Animator, id: u64, from: f32, to: f32, duration_seconds: f32, easing: Easing) !void {
        const duration = @max(0.0001, duration_seconds);
        try self.tracks.put(id, .{
            .id = id,
            .from = from,
            .to = to,
            .value = from,
            .duration = duration,
            .elapsed = 0.0,
            .easing = easing,
            .playing = true,
        });
    }

    pub fn stop(self: *Animator, id: u64) void {
        if (self.tracks.getPtr(id)) |track| {
            track.playing = false;
        }
    }

    pub fn setValue(self: *Animator, id: u64, value: f32) !void {
        if (self.tracks.getPtr(id)) |track| {
            track.value = value;
            track.from = value;
            track.to = value;
            track.elapsed = track.duration;
            track.playing = false;
            return;
        }
        try self.tracks.put(id, .{
            .id = id,
            .from = value,
            .to = value,
            .value = value,
            .duration = 0.0001,
            .elapsed = 0.0001,
            .easing = .linear,
            .playing = false,
        });
    }

    pub fn isActive(self: *const Animator, id: u64) bool {
        const track = self.tracks.get(id) orelse return false;
        return track.playing;
    }

    pub fn valueOr(self: *const Animator, id: u64, fallback: f32) f32 {
        const track = self.tracks.get(id) orelse return fallback;
        return track.value;
    }

    pub fn update(self: *Animator, dt_seconds: f32) void {
        if (self.tracks.count() == 0) return;
        const dt = @max(0.0, dt_seconds);
        var it = self.tracks.iterator();
        while (it.next()) |entry| {
            var track = entry.value_ptr;
            if (!track.playing) continue;
            track.elapsed = @min(track.duration, track.elapsed + dt);
            const t = if (track.duration <= 0.0) 1.0 else (track.elapsed / track.duration);
            track.value = lerp(track.from, track.to, applyEasing(track.easing, t));
            if (track.elapsed >= track.duration) {
                track.playing = false;
                track.value = track.to;
            }
        }
    }
};

pub fn animateFloat(current: f32, target: f32, dt_seconds: f32, response_hz: f32) f32 {
    return smoothTowards(current, target, dt_seconds, response_hz);
}

pub fn animateColor(current: [4]f32, target: [4]f32, dt_seconds: f32, response_hz: f32) [4]f32 {
    return .{
        smoothTowards(current[0], target[0], dt_seconds, response_hz),
        smoothTowards(current[1], target[1], dt_seconds, response_hz),
        smoothTowards(current[2], target[2], dt_seconds, response_hz),
        smoothTowards(current[3], target[3], dt_seconds, response_hz),
    };
}

pub fn smoothTowards(current: f32, target: f32, dt_seconds: f32, response_hz: f32) f32 {
    if (reduced_motion_enabled) return target;
    if (!std.math.isFinite(current) or !std.math.isFinite(target)) return target;
    if (@abs(current - target) <= 0.0001) return target;
    const rate = @max(0.001, response_hz);
    const dt = std.math.clamp(dt_seconds, 0.0, 0.25);
    const blend = 1.0 - std.math.exp(-rate * dt);
    return current + (target - current) * blend;
}

pub fn setReducedMotionEnabled(enabled: bool) void {
    reduced_motion_enabled = enabled;
}

pub fn reducedMotionEnabled() bool {
    return reduced_motion_enabled;
}

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    const clamped = std.math.clamp(t, 0.0, 1.0);
    return a + (b - a) * clamped;
}

pub fn applyEasing(easing: Easing, t_raw: f32) f32 {
    const t = std.math.clamp(t_raw, 0.0, 1.0);
    return switch (easing) {
        .linear => t,
        .ease_in => t * t,
        .ease_out => 1.0 - (1.0 - t) * (1.0 - t),
        .ease_in_out => if (t < 0.5)
            2.0 * t * t
        else
            1.0 - std.math.pow(f32, -2.0 * t + 2.0, 2.0) / 2.0,
    };
}

test "animator progresses and settles at target" {
    var animator = Animator.init(std.testing.allocator);
    defer animator.deinit();

    try animator.start(42, 0.0, 100.0, 1.0, .linear);
    animator.update(0.5);
    const mid = animator.valueOr(42, 0.0);
    try std.testing.expect(mid > 40.0 and mid < 60.0);
    try std.testing.expect(animator.isActive(42));

    animator.update(0.6);
    try std.testing.expectEqual(@as(f32, 100.0), animator.valueOr(42, 0.0));
    try std.testing.expect(!animator.isActive(42));
}

test "apply easing endpoints are stable" {
    try std.testing.expectEqual(@as(f32, 0.0), applyEasing(.ease_in, 0.0));
    try std.testing.expectEqual(@as(f32, 1.0), applyEasing(.ease_in, 1.0));
    try std.testing.expectEqual(@as(f32, 0.0), applyEasing(.ease_out, 0.0));
    try std.testing.expectEqual(@as(f32, 1.0), applyEasing(.ease_out, 1.0));
}

test "smooth towards converges quickly" {
    var value: f32 = 0.0;
    var i: usize = 0;
    while (i < 30) : (i += 1) {
        value = smoothTowards(value, 1.0, 1.0 / 60.0, 12.0);
    }
    try std.testing.expect(value > 0.9);
}
