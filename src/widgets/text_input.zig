//! Text input widget
const std = @import("std");
const theme = @import("../themes/theme.zig");
const colors = @import("../themes/colors.zig");
const runtime = @import("../theme_engine/runtime.zig");
const style_sheet = @import("../theme_engine/style_sheet.zig");

pub const Options = struct {
    disabled: bool = false,
    read_only: bool = false,
    placeholder: []const u8 = "",
};

pub const TextInputState = struct {
    hovered: bool = false,
    focused: bool = false,
    active: bool = false,
};

/// Calculate default text input height
pub fn defaultHeight(t: *const theme.Theme, line_height: f32) f32 {
    const profile = runtime.getProfile();
    const base = line_height + t.spacing.sm * 2.0;
    return @max(base, profile.hit_target_min_px);
}

/// Update text input state
pub fn updateState(
    rect: struct { x: f32, y: f32, width: f32, height: f32 },
    mouse_pos: [2]f32,
    mouse_clicked: bool,
    currently_focused: bool,
) TextInputState {
    const inside =
        mouse_pos[0] >= rect.x and
        mouse_pos[0] <= rect.x + rect.width and
        mouse_pos[1] >= rect.y and
        mouse_pos[1] <= rect.y + rect.height;

    const allow_hover = runtime.allowHover();
    const hovered = allow_hover and inside;

    // Click to focus, click outside to unfocus
    const focused = if (mouse_clicked) inside else currently_focused;

    return .{
        .hovered = hovered,
        .focused = focused,
        .active = focused,
    };
}

/// Get fill paint for text input
pub fn getFillPaint(
    t: *const theme.Theme,
    state: TextInputState,
    opts: Options,
) style_sheet.Paint {
    const ss = runtime.getStyleSheet();
    const style = ss.text_input;

    if (opts.disabled) {
        return style.states.disabled.fill orelse
            style.fill orelse
            .{ .solid = colors.withAlpha(t.colors.surface, 0.5) };
    }

    if (opts.read_only) {
        return style.states.read_only.fill orelse
            style.fill orelse
            .{ .solid = t.colors.surface };
    }

    if (state.focused) {
        return style.states.focused.fill orelse
            style.fill orelse
            blendColors(t.colors.background, t.colors.primary, 0.05);
    }

    if (state.hovered) {
        return style.states.hover.fill orelse
            style.fill orelse
            blendColors(t.colors.background, t.colors.primary, 0.03);
    }

    return style.fill orelse .{ .solid = t.colors.background };
}

/// Get border color for text input
pub fn getBorderColor(
    t: *const theme.Theme,
    state: TextInputState,
    opts: Options,
) colors.Color {
    const ss = runtime.getStyleSheet();
    const style = ss.text_input;

    if (opts.disabled) {
        return style.states.disabled.border orelse
            style.border orelse
            colors.withAlpha(t.colors.border, 0.3);
    }

    if (state.focused) {
        return style.states.focused.border orelse
            style.border orelse
            t.colors.primary;
    }

    if (state.hovered) {
        return style.states.hover.border orelse
            style.border orelse
            colors.blend(t.colors.border, t.colors.primary, 0.2);
    }

    return style.border orelse t.colors.border;
}

/// Get text color
pub fn getTextColor(t: *const theme.Theme, opts: Options) colors.Color {
    const ss = runtime.getStyleSheet();

    if (opts.disabled) {
        return style_sheet.getDisabledTextColor(ss, t);
    }

    return ss.text_input.text orelse t.colors.text_primary;
}

/// Get placeholder text color
pub fn getPlaceholderColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.text_input.placeholder orelse t.colors.text_secondary;
}

/// Get selection color
pub fn getSelectionColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.text_input.selection orelse colors.withAlpha(t.colors.primary, 0.3);
}

/// Get caret color
pub fn getCaretColor(t: *const theme.Theme) colors.Color {
    const ss = runtime.getStyleSheet();
    return ss.text_input.caret orelse t.colors.primary;
}

fn blendColors(a: colors.Color, b: colors.Color, t_val: f32) style_sheet.Paint {
    return .{ .solid = colors.blend(a, b, t_val) };
}

// Helper for disabled text color
fn getDisabledTextColor(ss: style_sheet.StyleSheet, t: *const theme.Theme) colors.Color {
    _ = ss;
    return colors.withAlpha(t.colors.text_primary, 0.4);
}
