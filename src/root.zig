//! ziggy-ui: A production-quality GUI library for Zig
//!
//! Features:
//! - Docking system with multi-window support
//! - WebGPU rendering backend
//! - SDL3 platform backend
//! - Comprehensive widget library
//! - Runtime theming system
//! - Command-list based rendering

const std = @import("std");

// Re-export theme tokens directly
pub const theme = @import("themes/theme.zig");

// Theme engine
pub const theme_engine = struct {
    pub const ThemeEngine = @import("theme_engine/theme_engine.zig").ThemeEngine;
    pub const StyleSheet = @import("theme_engine/style_sheet.zig").StyleSheet;
    pub const Paint = @import("theme_engine/style_sheet.zig").Paint;
    pub const PlatformCaps = @import("theme_engine/profile.zig").PlatformCaps;
    pub const Profile = @import("theme_engine/profile.zig").Profile;
    pub const ProfileId = @import("theme_engine/profile.zig").ProfileId;
    pub const runtime = @import("theme_engine/runtime.zig");
};

// Core types
pub const core = struct {
    pub const Context = @import("core/context.zig").Context;
    pub const Rect = @import("core/context.zig").Rect;
    pub const Vec2 = @import("core/context.zig").Vec2;
    pub const Color = @import("core/context.zig").Color;
    pub const Theme = theme.Theme;
    pub const Mode = theme.Mode;

    pub const events = @import("core/events.zig");
    pub const Event = events.Event;
    pub const KeyEvent = events.KeyEvent;
    pub const Key = events.Key;
    pub const layout = @import("core/layout.zig");
};

// Platform abstraction
pub const platform = struct {
    pub const Platform = @import("platform/platform.zig").Platform;
    pub const PlatformBackend = @import("platform/platform.zig").PlatformBackend;
    pub const sdl3 = @import("platform/sdl3.zig");
};

// Window and docking system
pub const window = struct {
    pub const Window = @import("window/window.zig").Window;
    pub const WindowManager = @import("window/window.zig").WindowManager;
    pub const WindowId = @import("window/window.zig").WindowId;
    pub const DockGraph = @import("layout/dock_graph.zig").DockGraph;
    pub const DockNodeId = @import("layout/dock_graph.zig").DockNodeId;
};

// Widgets
pub const widgets = struct {
    pub const button = @import("widgets/button.zig");
    pub const ButtonOptions = button.Options;
    pub const ButtonState = button.ButtonState;

    pub const checkbox = @import("widgets/checkbox.zig");
    pub const text_input = @import("widgets/text_input.zig");
    pub const TextInputOptions = text_input.Options;
    pub const TextInputState = text_input.TextInputState;

    pub const text_editor = @import("widgets/text_editor.zig");
    pub const focus_ring = @import("widgets/focus_ring.zig");
    pub const kinetic_scroll = @import("widgets/kinetic_scroll.zig");
};

// Rendering system
pub const render = struct {
    pub const CommandList = @import("render/command_list.zig").CommandList;
    pub const Command = @import("render/command_list.zig").Command;
    pub const RenderBackend = @import("render/render.zig").RenderBackend;
    pub const Renderer = @import("render/render.zig").Renderer;
    pub const wgpu = @import("render/webgpu.zig");
};

// Convenience re-exports
pub const Rect = core.Rect;
pub const Vec2 = core.Vec2;
pub const Color = core.Color;
pub const Theme = core.Theme;
pub const Mode = core.Mode;

/// Library version
pub const version = "0.1.0";

comptime {
    // Ensure all modules are referenced
    _ = core;
    _ = platform;
    _ = render;
    _ = window;
    _ = widgets;
    _ = theme_engine;
    _ = theme;
}
