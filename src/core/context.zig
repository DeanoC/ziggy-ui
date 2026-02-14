//! GUI Context - Core drawing and state management
const std = @import("std");

/// 2D vector
pub const Vec2 = [2]f32;

/// RGBA color (0-1 range)
pub const Color = [4]f32;

/// Rectangle for positioning and clipping
pub const Rect = struct {
    min: Vec2,
    max: Vec2,

    pub fn fromMinSize(min: Vec2, extent: Vec2) Rect {
        return .{
            .min = min,
            .max = .{ min[0] + extent[0], min[1] + extent[1] },
        };
    }

    pub fn fromXYWH(x: f32, y: f32, w: f32, h: f32) Rect {
        return .{
            .min = .{ x, y },
            .max = .{ x + w, y + h },
        };
    }

    pub fn size(self: Rect) Vec2 {
        return .{ self.max[0] - self.min[0], self.max[1] - self.min[1] };
    }

    pub fn width(self: Rect) f32 {
        return self.max[0] - self.min[0];
    }

    pub fn height(self: Rect) f32 {
        return self.max[1] - self.min[1];
    }

    pub fn contains(self: Rect, point: Vec2) bool {
        return point[0] >= self.min[0] and
            point[0] <= self.max[0] and
            point[1] >= self.min[1] and
            point[1] <= self.max[1];
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return self.min[0] < other.max[0] and
            self.max[0] > other.min[0] and
            self.min[1] < other.max[1] and
            self.max[1] > other.min[1];
    }

    pub fn inset(self: Rect, amount: f32) Rect {
        return .{
            .min = .{ self.min[0] + amount, self.min[1] + amount },
            .max = .{ self.max[0] - amount, self.max[1] - amount },
        };
    }

    pub fn offset(self: Rect, delta: Vec2) Rect {
        return .{
            .min = .{ self.min[0] + delta[0], self.min[1] + delta[1] },
            .max = .{ self.max[0] + delta[0], self.max[1] + delta[1] },
        };
    }
};

/// Four-corner gradient colors
pub const Gradient4 = struct {
    tl: Color,
    tr: Color,
    bl: Color,
    br: Color,

    pub fn solid(color: Color) Gradient4 {
        return .{
            .tl = color,
            .tr = color,
            .bl = color,
            .br = color,
        };
    }

    pub fn horizontal(left: Color, right: Color) Gradient4 {
        return .{
            .tl = left,
            .tr = right,
            .bl = left,
            .br = right,
        };
    }

    pub fn vertical(top: Color, bottom: Color) Gradient4 {
        return .{
            .tl = top,
            .tr = top,
            .bl = bottom,
            .br = bottom,
        };
    }
};

/// Style for rectangle drawing
pub const RectStyle = struct {
    fill: ?Color = null,
    stroke: ?Color = null,
    thickness: f32 = 1.0,
};

/// Style for text drawing
pub const TextStyle = struct {
    color: Color,
    size: f32 = 14.0,
    font_family: ?[]const u8 = null,
};

/// Soft effect kinds for rounded rectangles
pub const SoftFxKind = enum(u8) {
    fill_soft = 0,
    stroke_soft = 1,
};

/// Blend modes
pub const BlendMode = enum(u8) {
    alpha = 0,
    additive = 1,
};

/// Font role for typography hierarchy
pub const FontRole = enum {
    body,
    heading,
    title,
    mono,
};

/// Texture handle
pub const Texture = u64;

/// Command list for deferred rendering
const CommandList = @import("../render/command_list.zig").CommandList;
const Theme = @import("../themes/theme.zig").Theme;
const input = @import("../input/input_state.zig");

/// Input backend interface
pub const InputBackend = struct {
    isHovered: *const fn (ctx: *Context, rect: Rect) bool,
    isClicked: *const fn (ctx: *Context, rect: Rect, button: MouseButton) bool,
    isDragging: *const fn (ctx: *Context, rect: Rect) bool,
    getMousePos: *const fn (ctx: *Context) Vec2,
    isMouseDown: *const fn (ctx: *Context, button: MouseButton) bool,
};

/// Mouse buttons
pub const MouseButton = enum {
    left,
    right,
    middle,
    back,
    forward,
};

/// Render backend interface
pub const RenderBackend = struct {
    drawRect: *const fn (ctx: *Context, rect: Rect, style: RectStyle) void,
    drawRectGradient: *const fn (ctx: *Context, rect: Rect, colors: Gradient4) void,
    drawRoundedRect: *const fn (ctx: *Context, rect: Rect, radius: f32, style: RectStyle) void,
    drawRoundedRectGradient: *const fn (ctx: *Context, rect: Rect, radius: f32, colors: Gradient4) void,
    drawSoftRoundedRect: *const fn (
        ctx: *Context,
        draw_rect: Rect,
        rect: Rect,
        radius: f32,
        kind: SoftFxKind,
        thickness: f32,
        blur_px: f32,
        falloff_exp: f32,
        color: Color,
        respect_clip: bool,
        blend: BlendMode,
    ) void,
    drawText: *const fn (ctx: *Context, text: []const u8, pos: Vec2, style: TextStyle) void,
    drawLine: *const fn (ctx: *Context, from: Vec2, to: Vec2, width: f32, color: Color) void,
    drawImage: *const fn (ctx: *Context, texture: Texture, rect: Rect) void,
    drawImageUv: *const fn (ctx: *Context, texture: Texture, rect: Rect, uv0: Vec2, uv1: Vec2, tint: Color, repeat: bool) void,
    drawNineSlice: *const fn (
        ctx: *Context,
        texture: Texture,
        rect: Rect,
        slices_px: [4]f32,
        tint: Color,
        draw_center: bool,
        tile_center: bool,
        tile_center_x: bool,
        tile_center_y: bool,
        tile_anchor_end: bool,
    ) void,
    pushClip: *const fn (ctx: *Context, rect: Rect) void,
    popClip: *const fn (ctx: *Context) void,
    measureText: *const fn (ctx: *Context, text: []const u8, wrap_width: f32) Vec2,
    lineHeight: *const fn (ctx: *Context, font_size: f32) f32,
};

/// GUI Context - Main interface for drawing and interaction
pub const Context = struct {
    allocator: std.mem.Allocator,

    // Current theme
    theme: *const Theme,

    // Current viewport
    viewport: Rect,

    // Clip stack for scissoring
    clip_stack: std.ArrayList(Rect),

    // Render backend
    render: RenderBackend,

    // Input backend
    input: InputBackend,

    // Optional command list for deferred rendering
    command_list: ?*CommandList,

    // Current text metrics
    current_font_size: f32 = 14.0,
    current_font_role: FontRole = .body,

    pub fn init(
        allocator: std.mem.Allocator,
        theme: *const Theme,
        viewport: Rect,
        render_backend: RenderBackend,
        input_backend: InputBackend,
    ) Context {
        return .{
            .allocator = allocator,
            .theme = theme,
            .viewport = viewport,
            .clip_stack = .empty,
            .render = render_backend,
            .input = input_backend,
            .command_list = null,
            .current_font_size = theme.typography.body_size,
            .current_font_role = .body,
        };
    }

    pub fn deinit(self: *Context) void {
        self.clip_stack.deinit(self.allocator);
    }

    // Viewport management
    pub fn setViewport(self: *Context, viewport: Rect) void {
        self.viewport = viewport;
    }

    pub fn setTheme(self: *Context, theme: *const Theme) void {
        self.theme = theme;
    }

    // Clip stack operations
    pub fn pushClip(self: *Context, rect: Rect) void {
        // Intersect with current clip if any
        const effective_rect = if (self.clip_stack.items.len > 0) rect: {
            const current = self.clip_stack.items[self.clip_stack.items.len - 1];
            break :rect intersectRects(rect, current);
        } else rect: {
            break :rect rect;
        };

        self.render.pushClip(self, effective_rect);
        _ = self.clip_stack.append(self.allocator, effective_rect) catch {};
    }

    pub fn popClip(self: *Context) void {
        if (self.clip_stack.items.len == 0) return;
        _ = self.clip_stack.pop();
        self.render.popClip(self);
    }

    // Drawing primitives
    pub fn drawRect(self: *Context, rect: Rect, style: RectStyle) void {
        self.render.drawRect(self, rect, style);
    }

    pub fn drawRectGradient(self: *Context, rect: Rect, colors: Gradient4) void {
        self.render.drawRectGradient(self, rect, colors);
    }

    pub fn drawRoundedRect(self: *Context, rect: Rect, radius: f32, style: RectStyle) void {
        self.render.drawRoundedRect(self, rect, radius, style);
    }

    pub fn drawRoundedRectGradient(self: *Context, rect: Rect, radius: f32, colors: Gradient4) void {
        self.render.drawRoundedRectGradient(self, rect, radius, colors);
    }

    pub fn drawSoftRoundedRect(
        self: *Context,
        draw_rect: Rect,
        rect: Rect,
        radius: f32,
        kind: SoftFxKind,
        thickness: f32,
        blur_px: f32,
        falloff_exp: f32,
        color: Color,
        respect_clip: bool,
        blend: BlendMode,
    ) void {
        self.render.drawSoftRoundedRect(
            self,
            draw_rect,
            rect,
            radius,
            kind,
            thickness,
            blur_px,
            falloff_exp,
            color,
            respect_clip,
            blend,
        );
    }

    pub fn drawText(self: *Context, text: []const u8, pos: Vec2, style: TextStyle) void {
        self.render.drawText(self, text, pos, style);
    }

    pub fn drawLine(self: *Context, from: Vec2, to: Vec2, width: f32, color: Color) void {
        self.render.drawLine(self, from, to, width, color);
    }

    pub fn drawImage(self: *Context, texture: Texture, rect: Rect) void {
        self.render.drawImage(self, texture, rect);
    }

    pub fn drawImageUv(self: *Context, texture: Texture, rect: Rect, uv0: Vec2, uv1: Vec2, tint: Color, repeat: bool) void {
        self.render.drawImageUv(self, texture, rect, uv0, uv1, tint, repeat);
    }

    pub fn drawNineSlice(
        self: *Context,
        texture: Texture,
        rect: Rect,
        slices_px: [4]f32,
        tint: Color,
        draw_center: bool,
        tile_center: bool,
        tile_center_x: bool,
        tile_center_y: bool,
        tile_anchor_end: bool,
    ) void {
        self.render.drawNineSlice(self, texture, rect, slices_px, tint, draw_center, tile_center, tile_center_x, tile_center_y, tile_anchor_end);
    }

    // Input queries
    pub fn isHovered(self: *Context, rect: Rect) bool {
        return self.input.isHovered(self, rect);
    }

    pub fn isClicked(self: *Context, rect: Rect, button: MouseButton) bool {
        return self.input.isClicked(self, rect, button);
    }

    pub fn isDragging(self: *Context, rect: Rect) bool {
        return self.input.isDragging(self, rect);
    }

    pub fn getMousePos(self: *Context) Vec2 {
        return self.input.getMousePos(self);
    }

    pub fn isMouseDown(self: *Context, button: MouseButton) bool {
        return self.input.isMouseDown(self, button);
    }

    // Text measurement
    pub fn measureText(self: *Context, text: []const u8, wrap_width: f32) Vec2 {
        return self.render.measureText(self, text, wrap_width);
    }

    pub fn lineHeight(self: *Context) f32 {
        return self.render.lineHeight(self, self.current_font_size);
    }

    // Helper methods
    pub fn drawOverlayLabel(self: *Context, label: []const u8, pos: Vec2) void {
        const t = self.theme;
        const padding = t.spacing.xs;
        const text_size = self.measureText(label, 0.0);
        const rect_min = .{ pos[0] + 12.0, pos[1] + 12.0 };
        const rect = Rect.fromMinSize(
            rect_min,
            .{ text_size[0] + padding * 2.0, text_size[1] + padding * 2.0 },
        );
        self.drawRoundedRect(rect, t.radius.sm, .{
            .fill = .{ t.colors.surface[0], t.colors.surface[1], t.colors.surface[2], 0.95 },
            .stroke = .{ t.colors.border[0], t.colors.border[1], t.colors.border[2], 0.8 },
            .thickness = 1.0,
        });
        self.drawText(label, .{ rect.min[0] + padding, rect.min[1] + padding }, .{ .color = t.colors.text_primary });
    }
};

fn intersectRects(a: Rect, b: Rect) Rect {
    return .{
        .min = .{ @max(a.min[0], b.min[0]), @max(a.min[1], b.min[1]) },
        .max = .{ @min(a.max[0], b.max[0]), @min(a.max[1], b.max[1]) },
    };
}
