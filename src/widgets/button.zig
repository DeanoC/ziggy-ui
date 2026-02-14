//! Button widget
const std = @import("std");
const theme = @import("../themes/theme.zig");
const colors = @import("../themes/colors.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");

pub const Variant = enum {
    primary,
    secondary,
    ghost,
};

pub const Options = struct {
    disabled: bool = false,
    variant: Variant = .secondary,
    radius: ?f32 = null,
    style_override: ?*const style_sheet.ButtonVariantStyle = null,
};

/// Calculate default button height
pub fn defaultHeight(t: *const theme.Theme, line_height: f32) f32 {
    const profile = runtime.getProfile();
    const base = line_height + t.spacing.xs * 2.0;
    return @max(base, profile.hit_target_min_px);
}

/// Button state for immediate mode UI
pub const ButtonState = struct {
    hovered: bool = false,
    pressed: bool = false,
    clicked: bool = false,
    focused: bool = false,
};

/// Update button state (call each frame)
pub fn updateState(
    rect: struct { x: f32, y: f32, width: f32, height: f32 },
    mouse_pos: [2]f32,
    mouse_down: bool,
    opts: Options,
) ButtonState {
    _ = opts;
    const inside = 
        mouse_pos[0] >= rect.x and 
        mouse_pos[0] <= rect.x + rect.width and
        mouse_pos[1] >= rect.y and 
        mouse_pos[1] <= rect.y + rect.height;
    
    const allow_hover = runtime.allowHover();
    const hovered = allow_hover and inside;
    const pressed = inside and mouse_down;

    return .{
        .hovered = hovered,
        .pressed = pressed,
        .clicked = hovered and !mouse_down, // Simplified - real impl would track click start
        .focused = false, // Would come from navigation system
    };
}

/// Get paint for button background
pub fn getBackgroundPaint(
    t: *const theme.Theme,
    state: ButtonState,
    variant: Variant,
    style_override: ?*const style_sheet.ButtonVariantStyle,
) style_sheet.Paint {
    const ss = runtime.getStyleSheet();
    const variant_style_base = switch (variant) {
        .primary => ss.button.primary,
        .secondary => ss.button.secondary,
        .ghost => ss.button.ghost,
    };
    
    var variant_style = variant_style_base;
    if (style_override) |ov| {
        if (ov.fill) |v| variant_style.fill = v;
    }

    const white: colors.Color = .{ 1.0, 1.0, 1.0, 1.0 };
    const transparent: colors.Color = .{ 0.0, 0.0, 0.0, 0.0 };

    const base_bg = switch (variant) {
        .primary => variant_style.fill orelse .{ .solid = t.colors.primary },
        .secondary => variant_style.fill orelse .{ .solid = t.colors.surface },
        .ghost => variant_style.fill orelse .{ .solid = transparent },
    };

    if (state.disabled) {
        return base_bg;
    } else if (state.pressed) {
        // Blend with primary color
        return switch (variant) {
            .primary => blendPaint(base_bg, white, 0.2),
            .secondary => blendPaint(base_bg, t.colors.primary, 0.12),
            .ghost => .{ .solid = colors.withAlpha(t.colors.primary, 0.16) },
        };
    } else if (state.hovered) {
        return switch (variant) {
            .primary => blendPaint(base_bg, white, 0.12),
            .secondary => blendPaint(base_bg, t.colors.primary, 0.06),
            .ghost => .{ .solid = colors.withAlpha(t.colors.primary, 0.08) },
        };
    }

    return base_bg;
}

/// Get text color for button
pub fn getTextColor(t: *const theme.Theme, state: ButtonState, variant: Variant) colors.Color {
    if (state.disabled) {
        return colors.withAlpha(t.colors.text_primary, 0.4);
    }
    return switch (variant) {
        .primary => colors.withAlpha(t.colors.text_primary, 0.9),
        .secondary => t.colors.text_primary,
        .ghost => t.colors.primary,
    };
}

fn blendPaint(paint: style_sheet.Paint, over: colors.Color, factor: f32) style_sheet.Paint {
    return switch (paint) {
        .solid => |c| .{ .solid = colors.blend(c, over, factor) },
        .gradient4 => |g| .{ .gradient4 = .{
            .tl = colors.blend(g.tl, over, factor),
            .tr = colors.blend(g.tr, over, factor),
            .bl = colors.blend(g.bl, over, factor),
            .br = colors.blend(g.br, over, factor),
        } },
        .image => paint,
    };
}
