const theme = @import("../theme.zig");
const colors = @import("../theme/colors.zig");
const runtime = @import("runtime.zig");
const style_sheet = @import("style_sheet.zig");

pub const ListRowResolved = struct {
    fill: colors.Color,
    border: colors.Color,
    text: colors.Color,
};

pub const TabFallbackOptions = struct {
    radius: f32,
    inactive_fill_alpha: f32,
    hover_fill_alpha: f32,
    active_fill_alpha: f32,
    inactive_border_alpha: f32,
    active_border: colors.Color,
    inactive_text: colors.Color,
    active_text: colors.Color,
};

pub const TabResolved = struct {
    radius: f32,
    fill: style_sheet.Paint,
    border: colors.Color,
    text: colors.Color,
};

pub fn resolveListRow(t: *const theme.Theme, selected: bool, hovered: bool) ListRowResolved {
    const row = runtime.getStyleSheet().list_row;
    return .{
        .fill = if (selected and hovered)
            row.selected_hover_fill orelse row.selected_fill orelse colors.withAlpha(t.colors.primary, 0.16)
        else if (selected)
            row.selected_fill orelse colors.withAlpha(t.colors.primary, 0.12)
        else if (hovered)
            row.hover_fill orelse colors.withAlpha(t.colors.primary, 0.06)
        else
            colors.withAlpha(t.colors.surface, 0.0),
        .border = if (selected)
            row.selected_border orelse colors.blend(t.colors.border, t.colors.primary, 0.22)
        else if (hovered)
            row.hover_border orelse colors.withAlpha(t.colors.border, 0.28)
        else
            colors.withAlpha(t.colors.border, 0.0),
        .text = if (selected)
            row.selected_text orelse t.colors.text_primary
        else
            t.colors.text_primary,
    };
}

pub fn resolveTab(t: *const theme.Theme, active: bool, hovered: bool, opts: TabFallbackOptions) TabResolved {
    const tabs = runtime.getStyleSheet().tabs;
    var fill = tabs.fill orelse style_sheet.Paint{ .solid = colors.withAlpha(t.colors.surface, opts.inactive_fill_alpha) };
    var border = tabs.border orelse colors.withAlpha(t.colors.border, opts.inactive_border_alpha);
    var text = tabs.text orelse opts.inactive_text;

    if (active) {
        if (tabs.states.active.fill) |value| {
            fill = value;
        } else {
            fill = style_sheet.Paint{ .solid = colors.withAlpha(t.colors.primary, opts.active_fill_alpha) };
        }
        border = tabs.states.active.border orelse tabs.border orelse opts.active_border;
        text = tabs.states.active.text orelse tabs.text orelse opts.active_text;
    }

    if (hovered) {
        const hover_state = if (active and tabs.states.active_hover.isSet())
            tabs.states.active_hover
        else
            tabs.states.hover;

        if (hover_state.fill) |value| {
            fill = value;
        } else if (!active) {
            fill = style_sheet.Paint{ .solid = colors.withAlpha(t.colors.primary, opts.hover_fill_alpha) };
        }
        if (hover_state.border) |value| border = value;
        if (hover_state.text) |value| text = value;
    }

    return .{
        .radius = tabs.radius orelse opts.radius,
        .fill = fill,
        .border = border,
        .text = text,
    };
}

pub fn resolveShellHeaderPaint(t: *const theme.Theme, fallback_alpha: f32) style_sheet.Paint {
    const ss = runtime.getStyleSheet();
    return ss.shell.panel_header_fill orelse ss.panel.header_overlay orelse style_sheet.Paint{
        .solid = colors.withAlpha(t.colors.surface, fallback_alpha),
    };
}
