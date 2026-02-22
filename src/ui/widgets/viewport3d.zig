const std = @import("std");
const draw_context = @import("../draw_context.zig");
const input_state = @import("../input/input_state.zig");
const ui_systems = @import("../ui_systems.zig");
const colors = @import("../theme/colors.zig");

pub const Viewport3DId = []const u8;

pub const Viewport3DOptions = struct {
    background: [4]f32 = .{ 0.08, 0.10, 0.12, 1.0 },
    show_grid: bool = true,
    show_axes: bool = true,
    auto_rotate: bool = false,
    model_scale: f32 = 1.0,
};

pub const CameraOrbitState = struct {
    yaw: f32 = 0.7,
    pitch: f32 = 0.5,
    distance: f32 = 5.0,
};

pub const DrawResult = struct {
    hovered: bool = false,
    dragging: bool = false,
    camera: CameraOrbitState = .{},
};

const ViewState = struct {
    id_hash: u64 = 0,
    camera: CameraOrbitState = .{},
    dragging: bool = false,
    last_mouse: [2]f32 = .{ 0.0, 0.0 },
};

const max_states = 32;
var states: [max_states]ViewState = undefined;
var states_len: usize = 0;

pub fn draw(
    dc: *draw_context.DrawContext,
    queue: *input_state.InputQueue,
    id: Viewport3DId,
    rect: draw_context.Rect,
    options: Viewport3DOptions,
) DrawResult {
    var result: DrawResult = .{};
    if (rect.size()[0] <= 4.0 or rect.size()[1] <= 4.0) return result;

    var state = stateFor(id);
    const hovered = rect.contains(queue.state.mouse_pos);
    result.hovered = hovered;

    for (queue.events.items) |evt| {
        switch (evt) {
            .mouse_down => |md| {
                if (md.button == .left and rect.contains(md.pos)) {
                    state.dragging = true;
                    state.last_mouse = md.pos;
                }
            },
            .mouse_up => |mu| {
                if (mu.button == .left) {
                    state.dragging = false;
                }
            },
            .mouse_move => |mv| {
                if (state.dragging) {
                    const dx = mv.pos[0] - state.last_mouse[0];
                    const dy = mv.pos[1] - state.last_mouse[1];
                    state.camera.yaw += dx * 0.012;
                    state.camera.pitch = std.math.clamp(state.camera.pitch - dy * 0.012, -1.3, 1.3);
                    state.last_mouse = mv.pos;
                }
            },
            .mouse_wheel => |mw| {
                if (hovered) {
                    state.camera.distance = std.math.clamp(state.camera.distance - mw.delta[1] * 0.35, 1.8, 20.0);
                }
            },
            else => {},
        }
    }

    if (options.auto_rotate and !state.dragging) {
        state.camera.yaw += ui_systems.frameDtSeconds() * 0.5;
    }

    const t = dc.theme;
    dc.drawRoundedRect(rect, t.radius.md, .{
        .fill = options.background,
        .stroke = t.colors.border,
        .thickness = 1.0,
    });
    dc.pushClip(rect);
    defer dc.popClip();

    const view = ViewTransform{
        .center = .{
            rect.min[0] + rect.size()[0] * 0.5,
            rect.min[1] + rect.size()[1] * 0.5,
        },
        .scale = @min(rect.size()[0], rect.size()[1]) * 0.36,
        .camera = state.camera,
    };

    if (options.show_grid) {
        drawGrid(dc, view, colors.withAlpha(t.colors.text_secondary, 0.18));
    }
    if (options.show_axes) {
        drawAxes(dc, view);
    }
    drawCube(dc, view, options.model_scale, colors.withAlpha(t.colors.primary, 0.9));

    result.dragging = state.dragging;
    result.camera = state.camera;
    return result;
}

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

const ViewTransform = struct {
    center: [2]f32,
    scale: f32,
    camera: CameraOrbitState,
};

fn drawGrid(dc: *draw_context.DrawContext, view: ViewTransform, color: [4]f32) void {
    var i: i32 = -4;
    while (i <= 4) : (i += 1) {
        const f = @as(f32, @floatFromInt(i));
        drawProjectedLine(dc, view, .{ .x = -2.0, .y = -1.2, .z = f * 0.5 }, .{ .x = 2.0, .y = -1.2, .z = f * 0.5 }, color, 1.0);
        drawProjectedLine(dc, view, .{ .x = f * 0.5, .y = -1.2, .z = -2.0 }, .{ .x = f * 0.5, .y = -1.2, .z = 2.0 }, color, 1.0);
    }
}

fn drawAxes(dc: *draw_context.DrawContext, view: ViewTransform) void {
    drawProjectedLine(dc, view, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 1.2, .y = 0.0, .z = 0.0 }, .{ 1.0, 0.35, 0.35, 1.0 }, 2.0);
    drawProjectedLine(dc, view, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 0.0, .y = 1.2, .z = 0.0 }, .{ 0.45, 0.95, 0.45, 1.0 }, 2.0);
    drawProjectedLine(dc, view, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 0.0, .y = 0.0, .z = 1.2 }, .{ 0.45, 0.65, 1.0, 1.0 }, 2.0);
}

fn drawCube(dc: *draw_context.DrawContext, view: ViewTransform, scale: f32, color: [4]f32) void {
    const s = @max(0.2, scale) * 0.75;
    const v = [_]Vec3{
        .{ .x = -s, .y = -s, .z = -s },
        .{ .x = s, .y = -s, .z = -s },
        .{ .x = s, .y = s, .z = -s },
        .{ .x = -s, .y = s, .z = -s },
        .{ .x = -s, .y = -s, .z = s },
        .{ .x = s, .y = -s, .z = s },
        .{ .x = s, .y = s, .z = s },
        .{ .x = -s, .y = s, .z = s },
    };

    const edges = [_][2]usize{
        .{ 0, 1 }, .{ 1, 2 }, .{ 2, 3 }, .{ 3, 0 },
        .{ 4, 5 }, .{ 5, 6 }, .{ 6, 7 }, .{ 7, 4 },
        .{ 0, 4 }, .{ 1, 5 }, .{ 2, 6 }, .{ 3, 7 },
    };

    for (edges) |edge| {
        drawProjectedLine(dc, view, v[edge[0]], v[edge[1]], color, 1.7);
    }
}

fn drawProjectedLine(
    dc: *draw_context.DrawContext,
    view: ViewTransform,
    a: Vec3,
    b: Vec3,
    color: [4]f32,
    width: f32,
) void {
    const pa = projectPoint(view, a) orelse return;
    const pb = projectPoint(view, b) orelse return;
    dc.drawLine(pa, pb, width, color);
}

fn projectPoint(view: ViewTransform, point: Vec3) ?[2]f32 {
    const yaw = view.camera.yaw;
    const pitch = view.camera.pitch;

    const cy = std.math.cos(yaw);
    const sy = std.math.sin(yaw);
    const cp = std.math.cos(pitch);
    const sp = std.math.sin(pitch);

    const x1 = point.x * cy - point.z * sy;
    const z1 = point.x * sy + point.z * cy;
    const y2 = point.y * cp - z1 * sp;
    const z2 = point.y * sp + z1 * cp;

    const camera_z = z2 + view.camera.distance;
    if (camera_z <= 0.05) return null;

    const perspective = view.scale / camera_z;
    return .{
        view.center[0] + x1 * perspective,
        view.center[1] - y2 * perspective,
    };
}

fn stateFor(id: []const u8) *ViewState {
    const hash = std.hash.Wyhash.hash(0, id);
    var idx: usize = 0;
    while (idx < states_len) : (idx += 1) {
        if (states[idx].id_hash == hash) return &states[idx];
    }

    if (states_len < max_states) {
        states[states_len] = .{
            .id_hash = hash,
            .camera = .{},
            .dragging = false,
            .last_mouse = .{ 0.0, 0.0 },
        };
        states_len += 1;
        return &states[states_len - 1];
    }

    // Recycle the oldest slot as a controlled eviction path.
    states[0] = .{
        .id_hash = hash,
        .camera = .{},
        .dragging = false,
        .last_mouse = .{ 0.0, 0.0 },
    };
    return &states[0];
}

test "project point returns finite coordinates for visible points" {
    const view = ViewTransform{
        .center = .{ 100.0, 60.0 },
        .scale = 50.0,
        .camera = .{},
    };
    const p = projectPoint(view, .{ .x = 0.5, .y = 0.2, .z = 0.0 }) orelse return error.TestExpectedVisiblePoint;
    try std.testing.expect(std.math.isFinite(p[0]));
    try std.testing.expect(std.math.isFinite(p[1]));
}
