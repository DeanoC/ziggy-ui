//! Focus ring widget
const std = @import("std");
const theme = @import("../themes/theme.zig");
const colors = @import("../themes/colors.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");

/// Focus ring style options
pub const Options = struct {
    thickness: f32 = 2.0,
    inset: bool = false,
};

/// Get focus ring color
pub fn getColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.focus_ring.color orelse t.colors.primary;
}

/// Get focus ring thickness
pub fn getThickness(_t: *const theme.Theme) f32 {
    _ = _t;
    const ss = runtime.getStyleSheet();
    return ss.focus_ring.thickness orelse 2.0;
}

/// Get focus ring glow color
pub fn getGlowColor(_t: *const theme.Theme) ?colors.Color {
    _ = _t;
    const ss = runtime.getStyleSheet();
    return ss.focus_ring.glow.color;
}

/// Calculate focus ring rectangle
pub fn calculateRect(
    widget_rect: struct { x: f32, y: f32, width: f32, height: f32 },
    thickness: f32,
    inset: bool,
) struct { x: f32, y: f32, width: f32, height: f32 } {
    if (inset) {
        return .{
            .x = widget_rect.x + thickness,
            .y = widget_rect.y + thickness,
            .width = widget_rect.width - thickness * 2.0,
            .height = widget_rect.height - thickness * 2.0,
        };
    } else {
        return .{
            .x = widget_rect.x - thickness,
            .y = widget_rect.y - thickness,
            .width = widget_rect.width + thickness * 2.0,
            .height = widget_rect.height + thickness * 2.0,
        };
    }
}
