//! Theme token definitions
//! 
//! Theme tokens are the base visual values (colors, spacing, typography, etc.)
//! that define the look and feel of the UI.

pub const colors = @import("colors.zig");
pub const typography = @import("typography.zig");
pub const spacing = @import("spacing.zig");

/// Shadow definition
pub const Shadow = struct {
    blur: f32,
    spread: f32,
    offset_x: f32,
    offset_y: f32,
};

/// Collection of shadow sizes
pub const Shadows = struct {
    sm: Shadow,
    md: Shadow,
    lg: Shadow,
};

/// Complete theme definition
pub const Theme = struct {
    colors: colors.Colors,
    typography: typography.Typography,
    spacing: spacing.Spacing,
    radius: spacing.Radius,
    shadows: Shadows,
};

/// Theme variant modes
pub const Mode = enum { light, dark };

/// Light theme preset
pub const light = Theme{
    .colors = colors.light,
    .typography = typography.default,
    .spacing = spacing.default_spacing,
    .radius = spacing.default_radius,
    .shadows = .{
        .sm = .{ .blur = 2.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 1.0 },
        .md = .{ .blur = 4.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 2.0 },
        .lg = .{ .blur = 8.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 4.0 },
    },
};

/// Dark theme preset
pub const dark = Theme{
    .colors = colors.dark,
    .typography = typography.default,
    .spacing = spacing.default_spacing,
    .radius = spacing.default_radius,
    .shadows = .{
        .sm = .{ .blur = 2.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 1.0 },
        .md = .{ .blur = 4.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 2.0 },
        .lg = .{ .blur = 8.0, .spread = 0.0, .offset_x = 0.0, .offset_y = 4.0 },
    },
};

/// Get theme by mode
pub fn get(mode: Mode) *const Theme {
    return switch (mode) {
        .light => &light,
        .dark => &dark,
    };
}

// Runtime theme pointers for dynamic theming
var runtime_light: ?*const Theme = null;
var runtime_dark: ?*const Theme = null;

/// Set runtime theme for a mode (used by theme engine)
pub fn setRuntimeTheme(mode: Mode, theme_ptr: ?*const Theme) void {
    switch (mode) {
        .light => runtime_light = theme_ptr,
        .dark => runtime_dark = theme_ptr,
    }
}

/// Get the current mode (placeholder - apps should implement their own state)
var current_mode: Mode = .dark;

/// Set the current theme mode
pub fn setMode(mode: Mode) void {
    current_mode = mode;
}

/// Get the current theme mode
pub fn getMode() Mode {
    return current_mode;
}

/// Get the current theme
pub fn current() *const Theme {
    return get(getMode());
}
