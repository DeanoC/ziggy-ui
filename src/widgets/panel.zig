//! Panel widget
const std = @import("std");
const theme = @import("../themes/theme.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");

pub const Options = struct {
    radius: ?f32 = null,
    fill: ?style_sheet.Paint = null,
    border: ?style_sheet.BorderStyle = null,
    shadow: ?style_sheet.ShadowStyle = null,
};

pub const PanelState = struct {
    hovered: bool = false,
};

/// Update panel state
pub fn updateState(
    rect: struct { x: f32, y: f32, width: f32, height: f32 },
    mouse_pos: [2]f32,
) PanelState {
    const inside = 
        mouse_pos[0] >= rect.x and 
        mouse_pos[0] <= rect.x + rect.width and
        mouse_pos[1] >= rect.y and 
        mouse_pos[1] <= rect.y + rect.height;
    
    return .{
        .hovered = inside,
    };
}

/// Get fill paint for panel
pub fn getFillPaint(
    t: *const theme.Theme,
    opts: Options,
) style_sheet.Paint {
    if (opts.fill) |fill| return fill;
    return .{ .solid = t.colors.surface };
}

/// Get border style for panel
pub fn getBorderStyle(
    t: *const theme.Theme,
    opts: Options,
) ?style_sheet.BorderStyle {
    if (opts.border) |border| return border;
    return null;
}
