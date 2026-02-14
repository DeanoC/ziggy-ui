//! Checkbox widget
const std = @import("std");
const theme = @import("../themes/theme.zig");
const colors = @import("../themes/colors.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");

pub const Options = struct {
    disabled: bool = false,
    checked: bool = false,
};

pub const CheckboxState = struct {
    hovered: bool = false,
    pressed: bool = false,
    clicked: bool = false,
    checked: bool = false,
};

/// Calculate default checkbox size
pub fn defaultSize(t: *const theme.Theme) f32 {
    const profile = runtime.getProfile();
    const base = t.spacing.md;
    return @max(base, profile.hit_target_min_px * 0.6);
}

/// Update checkbox state
pub fn updateState(
    rect: struct { x: f32, y: f32, size: f32 },
    mouse_pos: [2]f32,
    mouse_down: bool,
    checked: bool,
    opts: Options,
) CheckboxState {
    _ = opts;
    const inside =
        mouse_pos[0] >= rect.x and
        mouse_pos[0] <= rect.x + rect.size and
        mouse_pos[1] >= rect.y and
        mouse_pos[1] <= rect.y + rect.size;

    const allow_hover = runtime.allowHover();
    const hovered = allow_hover and inside;
    const pressed = inside and mouse_down;

    return .{
        .hovered = hovered,
        .pressed = pressed,
        .clicked = hovered and !mouse_down,
        .checked = checked,
    };
}

/// Get fill paint for checkbox
pub fn getFillPaint(
    t: *const theme.Theme,
    state: CheckboxState,
    opts: Options,
) style_sheet.Paint {
    const ss = runtime.getStyleSheet();
    const style = ss.checkbox;

    if (opts.disabled) {
        return style.fill orelse .{ .solid = t.colors.surface };
    }

    if (state.checked) {
        if (state.hovered) {
            return style.states.hover.fill_checked orelse
                style.fill_checked orelse
                .{ .solid = t.colors.primary };
        }
        return style.fill_checked orelse .{ .solid = t.colors.primary };
    }

    if (state.hovered) {
        return style.states.hover.fill orelse
            style.fill orelse
            blendColors(t.colors.surface, t.colors.primary, 0.08);
    }

    return style.fill orelse .{ .solid = t.colors.surface };
}

/// Get border color for checkbox
pub fn getBorderColor(
    t: *const theme.Theme,
    state: CheckboxState,
    opts: Options,
) colors.Color {
    const ss = runtime.getStyleSheet();
    const style = ss.checkbox;

    if (opts.disabled) {
        return style.border orelse colors.withAlpha(t.colors.border, 0.5);
    }

    if (state.checked) {
        return style.border_checked orelse t.colors.primary;
    }

    if (state.hovered) {
        return style.states.hover.border orelse
            colors.blend(t.colors.border, t.colors.primary, 0.3);
    }

    return style.border orelse t.colors.border;
}

/// Get check mark color
pub fn getCheckColor(t: *const theme.Theme, opts: Options) colors.Color {
    _ = opts;
    const ss = runtime.getStyleSheet();
    return ss.checkbox.check orelse t.colors.text_primary;
}

fn blendColors(a: colors.Color, b: colors.Color, t_val: f32) style_sheet.Paint {
    return .{ .solid = colors.blend(a, b, t_val) };
}
