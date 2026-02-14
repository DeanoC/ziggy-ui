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

// Compatibility exports for the legacy UI tree used by ZiggyStarClaw.
// Consumers should prefer importing this package root (`@import("ziggy-ui")`) and
// selecting modules via this namespace instead of file-path imports/symlinks.
pub const ui = struct {
    pub const main_window = @import("ui/main_window.zig");
    pub const operator_view = @import("ui/operator_view.zig");
    pub const chat_view = @import("ui/chat_view.zig");
    pub const input_panel = @import("ui/input_panel.zig");
    pub const settings_view = @import("ui/settings_view.zig");
    pub const status_bar = @import("ui/status_bar.zig");
    pub const draw_context = @import("ui/draw_context.zig");
    pub const font_system = @import("ui/font_system.zig");
    pub const theme = @import("ui/theme.zig");
    pub const text_buffer = @import("ui/text_buffer.zig");
    pub const data_uri = @import("ui/data_uri.zig");
    pub const image_cache = @import("ui/image_cache.zig");
    pub const attachment_cache = @import("ui/attachment_cache.zig");
    pub const workspace = @import("ui/workspace.zig");
    pub const panel_manager = @import("ui/panel_manager.zig");
    pub const dock_transfer = @import("ui/dock_transfer.zig");
    pub const ui_command = @import("ui/ui_command.zig");
    pub const ui_command_inbox = @import("ui/ui_command_inbox.zig");
    pub const workspace_store = @import("ui/workspace_store.zig");
    pub const clipboard = @import("ui/clipboard.zig");
    pub const components = @import("ui/components/components.zig");
    pub const widgets = @import("ui/widgets/widgets.zig");

    pub const layout = struct {
        pub const custom_layout = @import("ui/layout/custom_layout.zig");
        pub const dock_graph = @import("ui/layout/dock_graph.zig");
        pub const dock_drop = @import("ui/layout/dock_drop.zig");
        pub const dock_detach = @import("ui/layout/dock_detach.zig");
        pub const dock_rail = @import("ui/layout/dock_rail.zig");
    };

    pub const input = struct {
        pub const input_router = @import("ui/input/input_router.zig");
        pub const input_backend = @import("ui/input/input_backend.zig");
        pub const sdl_input_backend = @import("ui/input/sdl_input_backend.zig");
        pub const text_input_backend = @import("ui/input/text_input_backend.zig");
        pub const input_state = @import("ui/input/input_state.zig");
    };

    pub const render = struct {
        pub const command_queue = @import("ui/render/command_queue.zig");
        pub const command_list = @import("ui/render/command_list.zig");
        pub const wgpu_renderer = @import("ui/render/wgpu_renderer.zig");
    };

    pub const theme_engine = struct {
        pub const theme_engine = @import("ui/theme_engine/theme_engine.zig");
        pub const profile = @import("ui/theme_engine/profile.zig");
        pub const style_sheet = @import("ui/theme_engine/style_sheet.zig");
        pub const runtime = @import("ui/theme_engine/runtime.zig");
        pub const schema = @import("ui/theme_engine/schema.zig");
        pub const builtin_packs = @import("ui/theme_engine/builtin_packs.zig");
        pub const theme_package = @import("ui/theme_engine/theme_package.zig");
        pub const winamp_import = @import("ui/theme_engine/winamp_import.zig");
    };
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
