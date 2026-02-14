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
const build_options = @import("build_options");

// Core modules
pub const core = struct {
    pub const Context = @import("core/context.zig").Context;
    pub const Event = @import("core/events.zig").Event;
    pub const EventQueue = @import("core/events.zig").EventQueue;
    pub const Rect = @import("core/context.zig").Rect;
    pub const Vec2 = @import("core/context.zig").Vec2;
    pub const Color = @import("core/context.zig").Color;
    pub const Gradient4 = @import("core/context.zig").Gradient4;
    pub const LayoutEngine = @import("core/layout.zig").LayoutEngine;
    pub const Theme = @import("themes/theme.zig").Theme;
    pub const Mode = @import("themes/theme.zig").Mode;
    pub const theme = @import("themes/theme.zig");
};

// Platform abstraction
pub const platform = struct {
    pub const PlatformBackend = @import("platform/platform.zig").PlatformBackend;
    pub const sdl3 = @import("platform/sdl3.zig");
};

// Rendering system
pub const render = struct {
    pub const CommandList = @import("render/command_list.zig").CommandList;
    pub const Command = @import("render/command_list.zig").Command;
    pub const RenderBackend = @import("render/render.zig").RenderBackend;
    pub const wgpu = @import("render/webgpu.zig");
};

// Window and docking system
pub const window = struct {
    pub const Window = @import("window/window.zig").Window;
    pub const WindowManager = @import("window/window.zig").WindowManager;
    pub const DockGraph = @import("window/dock.zig").DockGraph;
    pub const DockNode = @import("window/dock.zig").DockNode;
    pub const Panel = @import("window/dock.zig").Panel;
    pub const PanelId = @import("window/dock.zig").PanelId;
};

// Widgets
pub const widgets = struct {
    pub const Widget = @import("widgets/widget.zig").Widget;
    pub const Button = @import("widgets/button.zig").Button;
    pub const button = @import("widgets/button.zig");
    pub const Checkbox = @import("widgets/checkbox.zig").Checkbox;
    pub const checkbox = @import("widgets/checkbox.zig");
    pub const TextInput = @import("widgets/text_input.zig").TextInput;
    pub const text_input = @import("widgets/text_input.zig");
    pub const TextEditor = @import("widgets/text_editor.zig").TextEditor;
    pub const text_editor = @import("widgets/text_editor.zig");
    pub const Panel = @import("widgets/panel.zig").Panel;
    pub const panel = @import("widgets/panel.zig");
    pub const KineticScroll = @import("widgets/kinetic_scroll.zig").KineticScroll;
    pub const FocusRing = @import("widgets/focus_ring.zig").FocusRing;
};

// Input handling
pub const input = struct {
    pub const InputState = @import("input/input_state.zig").InputState;
    pub const InputQueue = @import("input/input_state.zig").InputQueue;
    pub const InputEvent = @import("input/input_state.zig").InputEvent;
    pub const MouseButton = @import("input/input_state.zig").MouseButton;
    pub const Key = @import("input/input_state.zig").Key;
    pub const Modifiers = @import("input/input_state.zig").Modifiers;
};

// Theme engine
pub const theme_engine = struct {
    pub const ThemeEngine = @import("theme_engine/theme_engine.zig").ThemeEngine;
    pub const StyleSheet = @import("theme_engine/style_sheet.zig").StyleSheet;
    pub const Paint = @import("theme_engine/style_sheet.zig").Paint;
};

// Convenience re-exports
pub const Context = core.Context;
pub const Rect = core.Rect;
pub const Vec2 = core.Vec2;
pub const Color = core.Color;
pub const Theme = core.Theme;
pub const Mode = core.Mode;

/// Library version
pub const version = "0.1.0";

/// Initialize the ziggy-ui library
pub fn init(allocator: std.mem.Allocator) void {
    _ = allocator;
    // Initialize any global state
}

/// Deinitialize the ziggy-ui library
pub fn deinit() void {
    // Cleanup any global state
}

comptime {
    // Ensure all modules are referenced
    _ = core;
    _ = platform;
    _ = render;
    _ = window;
    _ = widgets;
    _ = input;
    _ = theme_engine;
}
