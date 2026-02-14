//! Style sheet parsing and resolution
const std = @import("std");
const theme_tokens = @import("../themes/theme.zig");

pub const Color = [4]f32;

pub const BlendMode = enum {
    alpha,
    additive,
};

pub const Gradient4 = struct {
    tl: Color,
    tr: Color,
    bl: Color,
    br: Color,
};

pub const ImagePaintMode = enum {
    stretch,
    tile,
};

pub const ImagePaint = struct {
    path: AssetPath = .{},
    mode: ImagePaintMode = .stretch,
    scale: ?f32 = null,
    tint: ?Color = null,
    offset_px: ?[2]f32 = null,
};

pub const Paint = union(enum) {
    solid: Color,
    gradient4: Gradient4,
    image: ImagePaint,
};

pub const AssetPath = struct {
    len: u16 = 0,
    buf: [256]u8 = undefined,

    pub fn isSet(self: *const AssetPath) bool {
        return self.len != 0;
    }

    pub fn slice(self: *const AssetPath) []const u8 {
        return self.buf[0..self.len];
    }

    pub fn set(self: *AssetPath, s: []const u8) void {
        const n: usize = @min(s.len, self.buf.len);
        if (n == 0) {
            self.len = 0;
            return;
        }
        @memcpy(self.buf[0..n], s[0..n]);
        self.len = @intCast(n);
    }
};

pub const IconLabel = struct {
    len: u8 = 0,
    buf: [32]u8 = undefined,

    pub fn isSet(self: *const IconLabel) bool {
        return self.len != 0;
    }

    pub fn slice(self: *const IconLabel) []const u8 {
        return self.buf[0..self.len];
    }

    pub fn set(self: *IconLabel, s: []const u8) void {
        const n: usize = @min(s.len, self.buf.len);
        if (n == 0) {
            self.len = 0;
            return;
        }
        @memcpy(self.buf[0..n], s[0..n]);
        self.len = @intCast(n);
    }
};

// Button styles
pub const ButtonVariantStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,
    states: ButtonVariantStates = .{},
};

pub const ButtonVariantStateStyle = struct {
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,

    pub fn isSet(self: *const ButtonVariantStateStyle) bool {
        return self.fill != null or self.text != null or self.border != null;
    }
};

pub const ButtonVariantStates = struct {
    hover: ButtonVariantStateStyle = .{},
    pressed: ButtonVariantStateStyle = .{},
    disabled: ButtonVariantStateStyle = .{},
    focused: ButtonVariantStateStyle = .{},
};

pub const ButtonStyles = struct {
    primary: ButtonVariantStyle = .{},
    secondary: ButtonVariantStyle = .{},
    ghost: ButtonVariantStyle = .{},
};

// Checkbox styles
pub const CheckboxStateStyle = struct {
    fill: ?Paint = null,
    fill_checked: ?Paint = null,
    border: ?Color = null,
    border_checked: ?Color = null,
    check: ?Color = null,

    pub fn isSet(self: *const CheckboxStateStyle) bool {
        return self.fill != null or self.fill_checked != null or 
               self.border != null or self.border_checked != null or self.check != null;
    }
};

pub const CheckboxStates = struct {
    hover: CheckboxStateStyle = .{},
    pressed: CheckboxStateStyle = .{},
    disabled: CheckboxStateStyle = .{},
    focused: CheckboxStateStyle = .{},
};

pub const CheckboxStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    fill_checked: ?Paint = null,
    border: ?Color = null,
    border_checked: ?Color = null,
    check: ?Color = null,
    states: CheckboxStates = .{},
};

// Text input styles
pub const TextInputStateStyle = struct {
    fill: ?Paint = null,
    border: ?Color = null,
    text: ?Color = null,
    placeholder: ?Color = null,
    selection: ?Color = null,
    caret: ?Color = null,

    pub fn isSet(self: *const TextInputStateStyle) bool {
        return self.fill != null or self.border != null or self.text != null or
               self.placeholder != null or self.selection != null or self.caret != null;
    }
};

pub const TextInputStates = struct {
    hover: TextInputStateStyle = .{},
    pressed: TextInputStateStyle = .{},
    disabled: TextInputStateStyle = .{},
    focused: TextInputStateStyle = .{},
    read_only: TextInputStateStyle = .{},
};

pub const TextInputStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    border: ?Color = null,
    text: ?Color = null,
    placeholder: ?Color = null,
    selection: ?Color = null,
    caret: ?Color = null,
    states: TextInputStates = .{},
};

// Surface styles
pub const SurfacesStyle = struct {
    background: ?Paint = null,
    surface: ?Paint = null,
    menu_bar: ?Paint = null,
    status_bar: ?Paint = null,
};

// Panel styles
pub const PanelHeaderButtonsStyle = struct {
    close: ButtonVariantStyle = .{},
    detach: ButtonVariantStyle = .{},
};

pub const DockRailIconsStyle = struct {
    chat: IconLabel = .{},
    code_editor: IconLabel = .{},
    tool_output: IconLabel = .{},
    control: IconLabel = .{},
    agents: IconLabel = .{},
    operator: IconLabel = .{},
    approvals_inbox: IconLabel = .{},
    inbox: IconLabel = .{},
    workboard: IconLabel = .{},
    settings: IconLabel = .{},
    showcase: IconLabel = .{},
    collapse_left: IconLabel = .{},
    collapse_right: IconLabel = .{},
    pin: IconLabel = .{},
    close_flyout: IconLabel = .{},
};

pub const DockDropPreviewStyle = struct {
    inactive_fill: ?Paint = null,
    inactive_border: ?Color = null,
    inactive_thickness: ?f32 = null,
    active_fill: ?Paint = null,
    active_border: ?Color = null,
    active_thickness: ?f32 = null,
    marker: ?Color = null,
};

pub const PanelStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    border: ?Color = null,
    header_overlay: ?Paint = null,
    focus_border: ?Color = null,
    header_buttons: PanelHeaderButtonsStyle = .{},
    dock_rail_icons: DockRailIconsStyle = .{},
    dock_drop_preview: DockDropPreviewStyle = .{},
    content_inset_px: ?[4]f32 = null,
    overlay: ?Paint = null,
    shadow: EffectStyle = .{},
    frame_image: AssetPath = .{},
    frame_slices_px: ?[4]f32 = null,
    frame_tint: ?Color = null,
    frame_draw_center: bool = true,
    frame_center_overlay: ?Paint = null,
    frame_tile_center: bool = false,
    frame_tile_center_x: bool = true,
    frame_tile_center_y: bool = true,
    frame_tile_anchor_end: bool = false,
};

// Menu styles
pub const MenuItemStateStyle = struct {
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,

    pub fn isSet(self: *const MenuItemStateStyle) bool {
        return self.fill != null or self.text != null or self.border != null;
    }
};

pub const MenuItemStates = struct {
    hover: MenuItemStateStyle = .{},
    pressed: MenuItemStateStyle = .{},
    focused: MenuItemStateStyle = .{},
    disabled: MenuItemStateStyle = .{},
    selected: MenuItemStateStyle = .{},
    selected_hover: MenuItemStateStyle = .{},
};

pub const MenuItemStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,
    states: MenuItemStates = .{},
};

pub const MenuStyle = struct {
    item: MenuItemStyle = .{},
};

// Tab styles
pub const TabStateStyle = struct {
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,
    underline: ?Color = null,

    pub fn isSet(self: *const TabStateStyle) bool {
        return self.fill != null or self.text != null or 
               self.border != null or self.underline != null;
    }
};

pub const TabStates = struct {
    hover: TabStateStyle = .{},
    pressed: TabStateStyle = .{},
    focused: TabStateStyle = .{},
    disabled: TabStateStyle = .{},
    active: TabStateStyle = .{},
    active_hover: TabStateStyle = .{},
};

pub const TabsStyle = struct {
    radius: ?f32 = null,
    fill: ?Paint = null,
    text: ?Color = null,
    border: ?Color = null,
    underline: ?Color = null,
    underline_thickness: ?f32 = null,
    states: TabStates = .{},
};

// Focus ring styles
pub const FocusRingStyle = struct {
    thickness: ?f32 = null,
    color: ?Color = null,
    glow: EffectStyle = .{},
};

// Effect styles (shadows, glows)
pub const EffectStyle = struct {
    color: ?Color = null,
    blur_px: ?f32 = null,
    spread_px: ?f32 = null,
    offset: ?[2]f32 = null,
    steps: ?u8 = null,
    blend: ?BlendMode = null,
    falloff_exp: ?f32 = null,
    ignore_clip: ?bool = null,
};

/// Resolved style sheet (no allocations)
pub const StyleSheet = struct {
    surfaces: SurfacesStyle = .{},
    button: ButtonStyles = .{},
    checkbox: CheckboxStyle = .{},
    text_input: TextInputStyle = .{},
    panel: PanelStyle = .{},
    menu: MenuStyle = .{},
    tabs: TabsStyle = .{},
    focus_ring: FocusRingStyle = .{},
};

/// Style sheet store with raw JSON
pub const StyleSheetStore = struct {
    allocator: std.mem.Allocator,
    raw_json: []u8,
    resolved: StyleSheet,

    pub fn initEmpty(allocator: std.mem.Allocator) StyleSheetStore {
        return .{ .allocator = allocator, .raw_json = &[_]u8{}, .resolved = .{} };
    }

    pub fn deinit(self: *StyleSheetStore) void {
        if (self.raw_json.len > 0) self.allocator.free(self.raw_json);
        self.* = undefined;
    }
};

/// Parse style sheet from JSON bytes
pub fn parseResolved(
    allocator: std.mem.Allocator,
    json_bytes: []const u8,
    theme: *const theme_tokens.Theme,
) !StyleSheet {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
    defer parsed.deinit();

    var out: StyleSheet = .{};
    if (parsed.value != .object) return out;
    const root = parsed.value.object;

    if (root.get("surfaces")) |sv| {
        parseSurfaces(&out.surfaces, sv, theme);
    }
    if (root.get("button")) |btn_val| {
        parseButtons(&out.button, btn_val, theme);
    }
    if (root.get("checkbox")) |cb_val| {
        parseCheckbox(&out.checkbox, cb_val, theme);
    }
    if (root.get("text_input")) |ti_val| {
        parseTextInput(&out.text_input, ti_val, theme);
    }
    if (root.get("panel")) |panel_val| {
        parsePanel(&out.panel, panel_val, theme);
    }
    if (root.get("menu")) |menu_val| {
        parseMenu(&out.menu, menu_val, theme);
    }
    if (root.get("tabs")) |tabs_val| {
        parseTabs(&out.tabs, tabs_val, theme);
    }
    if (root.get("focus_ring")) |focus_val| {
        parseFocusRing(&out.focus_ring, focus_val, theme);
    }
    return out;
}

// Parser implementations (simplified - full implementation would be larger)
fn parseSurfaces(out: *SurfacesStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse surface styles
}

fn parseButtons(out: *ButtonStyles, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse button styles
}

fn parseCheckbox(out: *CheckboxStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse checkbox styles
}

fn parseTextInput(out: *TextInputStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse text input styles
}

fn parsePanel(out: *PanelStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse panel styles
}

fn parseMenu(out: *MenuStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse menu styles
}

fn parseTabs(out: *TabsStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse tab styles
}

fn parseFocusRing(out: *FocusRingStyle, v: std.json.Value, theme: *const theme_tokens.Theme) void {
    _ = out; _ = v; _ = theme;
    // Implementation would parse focus ring styles
}
