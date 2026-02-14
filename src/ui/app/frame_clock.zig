const std = @import("std");
const sdl_app = @import("sdl_app.zig");

pub const FrameInfo = struct {
    now_ms: i64,
    delta_seconds: f32,
};

pub const FrameClock = struct {
    target_frame_ms: u32,
    last_frame_ms: i64,
    frame_start_ms: i64 = 0,

    pub fn init(target_fps: u32) FrameClock {
        const now = std.time.milliTimestamp();
        const target_ms: u32 = if (target_fps == 0) 0 else @max(@as(u32, 1), 1000 / target_fps);
        return .{
            .target_frame_ms = target_ms,
            .last_frame_ms = now,
            .frame_start_ms = now,
        };
    }

    pub fn beginFrame(self: *FrameClock) FrameInfo {
        const now = std.time.milliTimestamp();
        const dt_ms = now - self.last_frame_ms;
        self.last_frame_ms = now;
        self.frame_start_ms = now;
        return .{
            .now_ms = now,
            .delta_seconds = @as(f32, @floatFromInt(dt_ms)) / 1000.0,
        };
    }

    pub fn endFrame(self: *FrameClock) void {
        if (self.target_frame_ms == 0) return;
        const now = std.time.milliTimestamp();
        const elapsed = now - self.frame_start_ms;
        if (elapsed < 0) return;
        const elapsed_u32: u32 = @intCast(elapsed);
        if (elapsed_u32 < self.target_frame_ms) {
            sdl_app.delayMs(self.target_frame_ms - elapsed_u32);
        }
    }
};
