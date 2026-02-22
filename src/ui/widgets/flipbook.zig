const std = @import("std");
const draw_context = @import("../draw_context.zig");
const image_cache = @import("../image_cache.zig");
const ui_systems = @import("../ui_systems.zig");

pub const Frame = struct {
    uv0: [2]f32 = .{ 0.0, 0.0 },
    uv1: [2]f32 = .{ 1.0, 1.0 },
    duration_ms: u16 = 120,
};

pub const Clip = struct {
    name: []const u8,
    frames: []const Frame,
    loop: bool = true,
    fps: f32 = 0.0,
};

pub const SpriteManifest = struct {
    atlas_url: []const u8,
    clips: []const Clip,
};

pub const DrawOptions = struct {
    clip_name: ?[]const u8 = null,
    autoplay: bool = true,
    speed: f32 = 1.0,
    tint: [4]f32 = .{ 1.0, 1.0, 1.0, 1.0 },
    repeat: bool = false,
};

pub const DrawResult = struct {
    ready: bool = false,
    clip_index: usize = 0,
    frame_index: usize = 0,
};

const PlayerState = struct {
    id_hash: u64 = 0,
    clip_index: usize = 0,
    frame_index: usize = 0,
    elapsed_s: f32 = 0.0,
    playing: bool = true,
    rate: f32 = 1.0,
};

const StateRef = struct {
    state: *PlayerState,
    created: bool = false,
};

const max_states = 64;
var states: [max_states]PlayerState = undefined;
var states_len: usize = 0;

pub fn draw(
    dc: *draw_context.DrawContext,
    rect: draw_context.Rect,
    id: []const u8,
    manifest: SpriteManifest,
    options: DrawOptions,
) DrawResult {
    var result = DrawResult{};
    if (manifest.clips.len == 0) {
        drawFallback(dc, rect, "No sprite clips");
        return result;
    }

    const state_ref = stateFor(id);
    var state = state_ref.state;
    if (state_ref.created) {
        state.playing = options.autoplay;
    }
    state.rate = @max(0.0, options.speed);

    if (options.clip_name) |clip_name| {
        if (findClipIndex(manifest, clip_name)) |clip_index| {
            if (state.clip_index != clip_index) {
                state.clip_index = clip_index;
                state.frame_index = 0;
                state.elapsed_s = 0.0;
            }
        }
    }
    if (state.clip_index >= manifest.clips.len) {
        state.clip_index = 0;
    }
    const clip = manifest.clips[state.clip_index];
    if (clip.frames.len == 0) {
        drawFallback(dc, rect, "Clip has no frames");
        return result;
    }
    if (state.frame_index >= clip.frames.len) {
        state.frame_index = 0;
        state.elapsed_s = 0.0;
    }

    const dt = ui_systems.frameDtSeconds();
    _ = advanceFrame(clip, &state.frame_index, &state.elapsed_s, dt, if (state.playing) state.rate else 0.0);

    image_cache.request(manifest.atlas_url);
    const atlas = image_cache.get(manifest.atlas_url);
    if (atlas == null or atlas.?.state != .ready) {
        drawFallback(dc, rect, "Loading sprite...");
        result.clip_index = state.clip_index;
        result.frame_index = state.frame_index;
        return result;
    }

    const frame = clip.frames[state.frame_index];
    const texture = draw_context.DrawContext.textureFromId(atlas.?.texture_id);
    dc.drawImageUv(texture, rect, frame.uv0, frame.uv1, options.tint, options.repeat);
    result.ready = true;
    result.clip_index = state.clip_index;
    result.frame_index = state.frame_index;
    return result;
}

pub fn play(id: []const u8) void {
    stateFor(id).state.playing = true;
}

pub fn pause(id: []const u8) void {
    stateFor(id).state.playing = false;
}

pub fn seek(id: []const u8, frame_index: usize) void {
    var state = stateFor(id).state;
    state.frame_index = frame_index;
    state.elapsed_s = 0.0;
}

pub fn setClip(id: []const u8, manifest: SpriteManifest, clip_name: []const u8) void {
    if (findClipIndex(manifest, clip_name)) |clip_index| {
        var state = stateFor(id).state;
        state.clip_index = clip_index;
        state.frame_index = 0;
        state.elapsed_s = 0.0;
    }
}

pub fn advanceFrame(
    clip: Clip,
    frame_index: *usize,
    elapsed_s: *f32,
    dt_seconds: f32,
    rate: f32,
) bool {
    if (clip.frames.len == 0) return false;
    if (rate <= 0.0 or dt_seconds <= 0.0) return false;

    elapsed_s.* += dt_seconds * rate;
    var wrapped = false;

    while (true) {
        const frame_duration_s = frameDurationSeconds(clip, frame_index.*);
        if (elapsed_s.* < frame_duration_s) break;
        elapsed_s.* -= frame_duration_s;
        if (frame_index.* + 1 < clip.frames.len) {
            frame_index.* += 1;
        } else if (clip.loop) {
            frame_index.* = 0;
            wrapped = true;
        } else {
            frame_index.* = clip.frames.len - 1;
            elapsed_s.* = 0.0;
            break;
        }
    }

    return wrapped;
}

fn frameDurationSeconds(clip: Clip, frame_index: usize) f32 {
    if (clip.fps > 0.001) {
        return 1.0 / clip.fps;
    }
    const frame = clip.frames[@min(frame_index, clip.frames.len - 1)];
    const duration_ms = @max(@as(u16, 1), frame.duration_ms);
    return @as(f32, @floatFromInt(duration_ms)) / 1000.0;
}

fn findClipIndex(manifest: SpriteManifest, clip_name: []const u8) ?usize {
    for (manifest.clips, 0..) |clip, idx| {
        if (std.mem.eql(u8, clip.name, clip_name)) return idx;
    }
    return null;
}

fn stateFor(id: []const u8) StateRef {
    const id_hash = std.hash.Wyhash.hash(0, id);
    var idx: usize = 0;
    while (idx < states_len) : (idx += 1) {
        if (states[idx].id_hash == id_hash) {
            return .{
                .state = &states[idx],
                .created = false,
            };
        }
    }

    if (states_len < max_states) {
        states[states_len] = .{
            .id_hash = id_hash,
            .clip_index = 0,
            .frame_index = 0,
            .elapsed_s = 0.0,
            .playing = true,
            .rate = 1.0,
        };
        states_len += 1;
        return .{
            .state = &states[states_len - 1],
            .created = true,
        };
    }

    // Recycle the oldest slot when the cache is full.
    states[0] = .{
        .id_hash = id_hash,
        .clip_index = 0,
        .frame_index = 0,
        .elapsed_s = 0.0,
        .playing = true,
        .rate = 1.0,
    };
    return .{
        .state = &states[0],
        .created = true,
    };
}

fn drawFallback(dc: *draw_context.DrawContext, rect: draw_context.Rect, label: []const u8) void {
    const t = dc.theme;
    dc.drawRoundedRect(rect, t.radius.sm, .{
        .fill = .{
            t.colors.surface[0],
            t.colors.surface[1],
            t.colors.surface[2],
            0.65,
        },
        .stroke = t.colors.border,
        .thickness = 1.0,
    });
    dc.drawText(label, .{ rect.min[0] + t.spacing.sm, rect.min[1] + t.spacing.sm }, .{ .color = t.colors.text_secondary });
}

test "advance frame loops when clip is configured to loop" {
    const frames = [_]Frame{
        .{ .duration_ms = 100 },
        .{ .duration_ms = 100 },
        .{ .duration_ms = 100 },
    };
    const clip = Clip{
        .name = "idle",
        .frames = frames[0..],
        .loop = true,
    };
    var frame_index: usize = 0;
    var elapsed: f32 = 0.0;
    _ = advanceFrame(clip, &frame_index, &elapsed, 0.35, 1.0);
    try std.testing.expectEqual(@as(usize, 0), frame_index);
}

test "advance frame clamps at end for non-loop clip" {
    const frames = [_]Frame{
        .{ .duration_ms = 50 },
        .{ .duration_ms = 50 },
    };
    const clip = Clip{
        .name = "once",
        .frames = frames[0..],
        .loop = false,
    };
    var frame_index: usize = 0;
    var elapsed: f32 = 0.0;
    _ = advanceFrame(clip, &frame_index, &elapsed, 0.4, 1.0);
    try std.testing.expectEqual(@as(usize, 1), frame_index);
}
