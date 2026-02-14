//! Theme engine for loading and managing theme packs
const std = @import("std");
const builtin = @import("builtin");

const theme_mod = @import("../themes/theme.zig");
const theme_tokens = @import("../themes/theme.zig");

const profile = @import("profile.zig");
pub const schema = @import("schema.zig");
const theme_package = @import("theme_package.zig");
const style_sheet = @import("style_sheet.zig");
const runtime = @import("runtime.zig");

pub const PlatformCaps = profile.PlatformCaps;
pub const ProfileId = profile.ProfileId;
pub const Profile = profile.Profile;

pub const EngineError = error{
    ThemePackLoadFailed,
} || theme_package.LoadError || std.mem.Allocator.Error;

/// Context for theme lookups
pub const ThemeContext = struct {
    profile: Profile,
    tokens: *const theme_tokens.Theme,
    styles: style_sheet.StyleSheet,
};

/// Main theme engine
pub const ThemeEngine = struct {
    allocator: std.mem.Allocator,
    caps: PlatformCaps,

    // Owned runtime themes
    runtime_light: ?*theme_tokens.Theme = null,
    runtime_dark: ?*theme_tokens.Theme = null,
    pack_tokens_light: ?schema.TokensFile = null,
    pack_tokens_dark: ?schema.TokensFile = null,

    // Per-profile caches
    profile_themes_light: [4]?*theme_tokens.Theme = .{ null, null, null, null },
    profile_themes_dark: [4]?*theme_tokens.Theme = .{ null, null, null, null },
    base_styles_light: style_sheet.StyleSheet = .{},
    base_styles_dark: style_sheet.StyleSheet = .{},
    profile_styles_light: [4]style_sheet.StyleSheet = .{ .{}, .{}, .{}, .{} },
    profile_styles_dark: [4]style_sheet.StyleSheet = .{ .{}, .{}, .{}, .{} },
    profile_styles_cached: [4]bool = .{ false, false, false, false },

    active_pack_path: ?[]u8 = null,
    active_pack_root: ?[]u8 = null,

    active_profile: Profile = profile.defaultsFor(.desktop, profile.PlatformCaps.defaultForTarget()),
    styles: style_sheet.StyleSheetStore,
    windows: ?[]schema.WindowTemplate = null,

    // Pack metadata
    pack_meta_set: bool = false,
    pack_meta_id: ?[]u8 = null,
    pack_meta_name: ?[]u8 = null,
    pack_meta_author: ?[]u8 = null,
    pack_meta_license: ?[]u8 = null,
    pack_meta_defaults_variant: ?[]u8 = null,
    pack_meta_defaults_profile: ?[]u8 = null,
    pack_defaults_lock_variant: bool = false,
    pack_meta_requires_multi_window: bool = false,
    pack_meta_requires_custom_shaders: bool = false,
    render_defaults: runtime.RenderDefaults = .{},

    pub fn init(allocator: std.mem.Allocator, caps: PlatformCaps) ThemeEngine {
        return .{
            .allocator = allocator,
            .caps = caps,
            .active_profile = profile.defaultsFor(.desktop, caps),
            .styles = style_sheet.StyleSheetStore.initEmpty(allocator),
            .windows = null,
        };
    }

    pub fn deinit(self: *ThemeEngine) void {
        // Detach from global theme
        theme_mod.setRuntimeTheme(.light, null);
        theme_mod.setRuntimeTheme(.dark, null);

        if (self.runtime_light) |ptr| freeTheme(self.allocator, ptr);
        if (self.runtime_dark) |ptr| freeTheme(self.allocator, ptr);
        self.runtime_light = null;
        self.runtime_dark = null;

        if (self.pack_tokens_light) |*t| self.allocator.free(t.typography.font_family);
        if (self.pack_tokens_dark) |*t| self.allocator.free(t.typography.font_family);
        self.pack_tokens_light = null;
        self.pack_tokens_dark = null;

        self.freeProfileCaches();

        if (self.active_pack_path) |p| self.allocator.free(p);
        self.active_pack_path = null;
        if (self.active_pack_root) |p| self.allocator.free(p);
        self.active_pack_root = null;

        if (self.windows) |v| theme_package.freeWindowTemplates(self.allocator, v);
        self.windows = null;

        self.clearPackMetaOwned();
        self.styles.deinit();

        runtime.setStyleSheets(.{}, .{});
        runtime.setThemePackRootPath(null);
        runtime.setWindowTemplates(&[_]schema.WindowTemplate{});
        runtime.clearPackDefaults();
        runtime.clearPackMeta();
    }

    fn clearPackMetaOwned(self: *ThemeEngine) void {
        if (self.pack_meta_id) |v| self.allocator.free(v);
        if (self.pack_meta_name) |v| self.allocator.free(v);
        if (self.pack_meta_author) |v| self.allocator.free(v);
        if (self.pack_meta_license) |v| self.allocator.free(v);
        if (self.pack_meta_defaults_variant) |v| self.allocator.free(v);
        if (self.pack_meta_defaults_profile) |v| self.allocator.free(v);
        self.pack_meta_id = null;
        self.pack_meta_name = null;
        self.pack_meta_author = null;
        self.pack_meta_license = null;
        self.pack_meta_defaults_variant = null;
        self.pack_meta_defaults_profile = null;
        self.pack_meta_set = false;
    }

    pub fn clearThemePack(self: *ThemeEngine) void {
        theme_mod.setRuntimeTheme(.light, null);
        theme_mod.setRuntimeTheme(.dark, null);

        if (self.runtime_light) |ptr| freeTheme(self.allocator, ptr);
        if (self.runtime_dark) |ptr| freeTheme(self.allocator, ptr);
        self.runtime_light = null;
        self.runtime_dark = null;

        if (self.pack_tokens_light) |*t| self.allocator.free(t.typography.font_family);
        if (self.pack_tokens_dark) |*t| self.allocator.free(t.typography.font_family);
        self.pack_tokens_light = null;
        self.pack_tokens_dark = null;

        self.freeProfileCaches();

        if (self.active_pack_path) |p| self.allocator.free(p);
        self.active_pack_path = null;
        if (self.active_pack_root) |p| self.allocator.free(p);
        self.active_pack_root = null;

        self.styles.deinit();
        self.styles = style_sheet.StyleSheetStore.initEmpty(self.allocator);

        if (self.windows) |v| theme_package.freeWindowTemplates(self.allocator, v);
        self.windows = null;

        self.clearPackMetaOwned();
        self.render_defaults = .{};

        runtime.setStyleSheets(.{}, .{});
        runtime.setThemePackRootPath(null);
        runtime.setWindowTemplates(&[_]schema.WindowTemplate{});
        runtime.setRenderDefaults(self.render_defaults);
        runtime.clearPackDefaults();
        runtime.clearPackMeta();
    }

    pub fn setProfile(self: *ThemeEngine, p: Profile) void {
        self.active_profile = p;
        runtime.setProfile(p);
    }

    pub fn resolveProfileFromConfig(
        self: *ThemeEngine,
        framebuffer_width: u32,
        framebuffer_height: u32,
        cfg_profile_label: ?[]const u8,
    ) void {
        const requested = profile.profileFromLabel(cfg_profile_label);
        const resolved = profile.resolveProfile(self.caps, framebuffer_width, framebuffer_height, requested);
        self.active_profile = resolved;
        runtime.setProfile(self.active_profile);
    }

    pub fn loadAndApplyThemePackDir(self: *ThemeEngine, root_path: []const u8) !void {
        var pack = try theme_package.loadFromPath(self.allocator, root_path);
        defer pack.deinit();

        const base_theme = try buildRuntimeTheme(self.allocator, pack.tokens_base);
        errdefer freeTheme(self.allocator, base_theme);

        const light_theme = if (pack.tokens_light) |tf|
            try buildRuntimeTheme(self.allocator, tf)
        else
            try cloneTheme(self.allocator, base_theme);
        errdefer freeTheme(self.allocator, light_theme);

        const dark_theme = if (pack.tokens_dark) |tf|
            try buildRuntimeTheme(self.allocator, tf)
        else
            try cloneTheme(self.allocator, base_theme);
        errdefer freeTheme(self.allocator, dark_theme);

        // Load style sheet
        self.styles.deinit();
        self.styles = try theme_package.loadStyleSheetFromDirectory(self.allocator, pack.root_path);
        
        if (self.styles.raw_json.len > 0) {
            const ss_light = try style_sheet.parseResolved(self.allocator, self.styles.raw_json, light_theme);
            const ss_dark = try style_sheet.parseResolved(self.allocator, self.styles.raw_json, dark_theme);
            runtime.setStyleSheets(ss_light, ss_dark);
            self.base_styles_light = ss_light;
            self.base_styles_dark = ss_dark;
        } else {
            runtime.setStyleSheets(.{}, .{});
            self.base_styles_light = .{};
            self.base_styles_dark = .{};
        }

        // Set themes
        theme_mod.setRuntimeTheme(.light, light_theme);
        theme_mod.setRuntimeTheme(.dark, dark_theme);

        // Set pack root
        if (self.active_pack_root) |p| self.allocator.free(p);
        self.active_pack_root = try self.allocator.dupe(u8, pack.root_path);
        runtime.setThemePackRootPath(self.active_pack_root);

        // Set metadata
        self.clearPackMetaOwned();
        self.pack_meta_set = true;
        self.pack_meta_id = try self.allocator.dupe(u8, pack.manifest.id);
        self.pack_meta_name = try self.allocator.dupe(u8, pack.manifest.name);
        self.pack_meta_author = try self.allocator.dupe(u8, pack.manifest.author);
        self.pack_meta_license = try self.allocator.dupe(u8, pack.manifest.license);
        self.pack_meta_defaults_variant = try self.allocator.dupe(u8, pack.manifest.defaults.variant);
        self.pack_meta_defaults_profile = try self.allocator.dupe(u8, pack.manifest.defaults.profile);
        self.pack_meta_requires_multi_window = pack.manifest.capabilities.requires_multi_window;
        self.pack_meta_requires_custom_shaders = pack.manifest.capabilities.requires_custom_shaders;
        self.pack_defaults_lock_variant = pack.manifest.defaults.lock_variant;

        runtime.setPackDefaults(pack.manifest.defaults.variant, pack.manifest.defaults.profile);
        runtime.setPackModeLockToDefault(self.pack_defaults_lock_variant);
        runtime.setPackMeta(pack.manifest);

        // Render defaults
        const defaults_sampling = if (std.ascii.eqlIgnoreCase(pack.manifest.defaults.image_sampling, "nearest"))
            runtime.ImageSampling.nearest
        else
            runtime.ImageSampling.linear;
        self.render_defaults = .{
            .image_sampling = defaults_sampling,
            .pixel_snap_textured = pack.manifest.defaults.pixel_snap_textured,
        };
        runtime.setRenderDefaults(self.render_defaults);

        // Windows
        if (self.windows) |v| theme_package.freeWindowTemplates(self.allocator, v);
        self.windows = pack.windows;
        pack.windows = null;
        runtime.setWindowTemplates(self.windows orelse &[_]schema.WindowTemplate{});

        // Store themes
        if (self.runtime_light) |prev| freeTheme(self.allocator, prev);
        if (self.runtime_dark) |prev| freeTheme(self.allocator, prev);
        self.runtime_light = light_theme;
        self.runtime_dark = dark_theme;

        // Store tokens
        if (self.pack_tokens_light) |*t| self.allocator.free(t.typography.font_family);
        if (self.pack_tokens_dark) |*t| self.allocator.free(t.typography.font_family);
        self.pack_tokens_light = try dupTokensFileAlloc(self.allocator, pack.tokens_light orelse pack.tokens_base);
        self.pack_tokens_dark = try dupTokensFileAlloc(self.allocator, pack.tokens_dark orelse pack.tokens_base);

        self.clearProfileThemeCaches();
        freeTheme(self.allocator, base_theme);
    }

    fn freeProfileCaches(self: *ThemeEngine) void {
        self.clearProfileThemeCaches();
    }

    fn clearProfileThemeCaches(self: *ThemeEngine) void {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            if (self.profile_themes_light[i]) |ptr| {
                if (self.runtime_light == null or ptr != self.runtime_light.?) freeTheme(self.allocator, ptr);
            }
            if (self.profile_themes_dark[i]) |ptr| {
                if (self.runtime_dark == null or ptr != self.runtime_dark.?) freeTheme(self.allocator, ptr);
            }
            self.profile_themes_light[i] = null;
            self.profile_themes_dark[i] = null;
            self.profile_styles_cached[i] = false;
            self.profile_styles_light[i] = .{};
            self.profile_styles_dark[i] = .{};
        }
    }
};

// Helper functions

fn dupTokensFileAlloc(allocator: std.mem.Allocator, src: schema.TokensFile) !schema.TokensFile {
    var out = src;
    out.typography.font_family = try allocator.dupe(u8, src.typography.font_family);
    return out;
}

fn buildRuntimeTheme(allocator: std.mem.Allocator, tokens: schema.TokensFile) !*theme_tokens.Theme {
    const font_family = try allocator.dupe(u8, tokens.typography.font_family);
    errdefer allocator.free(font_family);

    const out = try allocator.create(theme_tokens.Theme);
    out.* = .{
        .colors = .{
            .background = tokens.colors.background,
            .surface = tokens.colors.surface,
            .primary = tokens.colors.primary,
            .success = tokens.colors.success,
            .danger = tokens.colors.danger,
            .warning = tokens.colors.warning,
            .text_primary = tokens.colors.text_primary,
            .text_secondary = tokens.colors.text_secondary,
            .border = tokens.colors.border,
            .divider = tokens.colors.divider,
        },
        .typography = .{
            .font_family = font_family,
            .title_size = tokens.typography.title_size,
            .heading_size = tokens.typography.heading_size,
            .body_size = tokens.typography.body_size,
            .caption_size = tokens.typography.caption_size,
        },
        .spacing = .{
            .xs = tokens.spacing.xs,
            .sm = tokens.spacing.sm,
            .md = tokens.spacing.md,
            .lg = tokens.spacing.lg,
            .xl = tokens.spacing.xl,
        },
        .radius = .{
            .sm = tokens.radius.sm,
            .md = tokens.radius.md,
            .lg = tokens.radius.lg,
            .full = tokens.radius.full,
        },
        .shadows = .{
            .sm = .{ .blur = tokens.shadows.sm.blur, .spread = tokens.shadows.sm.spread, 
                     .offset_x = tokens.shadows.sm.offset_x, .offset_y = tokens.shadows.sm.offset_y },
            .md = .{ .blur = tokens.shadows.md.blur, .spread = tokens.shadows.md.spread, 
                     .offset_x = tokens.shadows.md.offset_x, .offset_y = tokens.shadows.md.offset_y },
            .lg = .{ .blur = tokens.shadows.lg.blur, .spread = tokens.shadows.lg.spread, 
                     .offset_x = tokens.shadows.lg.offset_x, .offset_y = tokens.shadows.lg.offset_y },
        },
    };
    return out;
}

fn cloneTheme(allocator: std.mem.Allocator, src: *theme_tokens.Theme) !*theme_tokens.Theme {
    const dup = try allocator.create(theme_tokens.Theme);
    errdefer allocator.destroy(dup);
    dup.* = src.*;
    dup.typography.font_family = try allocator.dupe(u8, src.typography.font_family);
    return dup;
}

fn freeTheme(allocator: std.mem.Allocator, t: *theme_tokens.Theme) void {
    allocator.free(t.typography.font_family);
    allocator.destroy(t);
}
