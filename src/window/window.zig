//! Window management
const std = @import("std");
const Rect = @import("../core/context.zig").Rect;
const Vec2 = @import("../core/context.zig").Vec2;
const DockGraph = @import("dock.zig").DockGraph;
const Panel = @import("dock.zig").Panel;
const PanelId = @import("dock.zig").PanelId;

/// Window ID
pub const WindowId = u32;

/// Window mode
pub const WindowMode = enum {
    windowed,
    maximized,
    fullscreen,
    minimized,
};

/// Window configuration
pub const WindowConfig = struct {
    title: []const u8 = "ziggy-ui",
    width: u32 = 1280,
    height: u32 = 720,
    mode: WindowMode = .windowed,
    resizable: bool = true,
    borderless: bool = false,
    transparent: bool = false,
    vsync: bool = true,
};

/// Window state
pub const Window = struct {
    id: WindowId,
    config: WindowConfig,

    // Current state
    rect: Rect,
    mode: WindowMode,
    focused: bool = true,

    // Content area (excluding decorations)
    content_rect: Rect,

    // Docking state for this window
    dock_graph: DockGraph,
    panels: std.AutoHashMap(PanelId, Panel),

    // Next panel ID
    next_panel_id: PanelId = 1,

    // Platform-specific handle (opaque)
    platform_handle: ?*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, id: WindowId, config: WindowConfig) Window {
        const rect = Rect.fromXYWH(100, 100, @floatFromInt(config.width), @floatFromInt(config.height));
        return .{
            .id = id,
            .config = config,
            .rect = rect,
            .mode = config.mode,
            .content_rect = rect,
            .dock_graph = DockGraph.init(allocator),
            .panels = std.AutoHashMap(PanelId, Panel).init(allocator),
        };
    }

    pub fn deinit(self: *Window, allocator: std.mem.Allocator) void {
        var panel_it = self.panels.valueIterator();
        while (panel_it.next()) |panel| {
            panel.deinit(allocator);
        }
        self.panels.deinit();
        self.dock_graph.deinit();
    }

    /// Create a new panel in this window
    pub fn createPanel(self: *Window, allocator: std.mem.Allocator, title: []const u8) !*Panel {
        const id = self.next_panel_id;
        self.next_panel_id += 1;

        const panel = try Panel.init(allocator, id, title);
        try self.panels.put(id, panel);

        // Add to dock graph
        _ = try self.dock_graph.addTabsNode(&[_]PanelId{id}, 0);

        return self.panels.getPtr(id).?;
    }

    /// Remove a panel
    pub fn removePanel(self: *Window, allocator: std.mem.Allocator, id: PanelId) void {
        _ = self.dock_graph.removePanel(id);
        if (self.panels.fetchRemove(id)) |kv| {
            kv.value.deinit(allocator);
        }
    }

    /// Get a panel by ID
    pub fn getPanel(self: *Window, id: PanelId) ?*Panel {
        return self.panels.getPtr(id);
    }

    /// Resize the window
    pub fn resize(self: *Window, width: u32, height: u32) void {
        self.rect.max[0] = self.rect.min[0] + @as(f32, @floatFromInt(width));
        self.rect.max[1] = self.rect.min[1] + @as(f32, @floatFromInt(height));
        self.content_rect = self.rect; // In a real implementation, account for decorations
    }

    /// Move the window
    pub fn move(self: *Window, x: f32, y: f32) void {
        const size = self.rect.size();
        self.rect.min = .{ x, y };
        self.rect.max = .{ x + size[0], y + size[1] };
    }

    /// Set window mode
    pub fn setMode(self: *Window, mode: WindowMode) void {
        self.mode = mode;
    }

    /// Set focus state
    pub fn setFocused(self: *Window, focused: bool) void {
        self.focused = focused;
    }
};

/// Window manager - manages multiple windows
pub const WindowManager = struct {
    allocator: std.mem.Allocator,
    windows: std.AutoHashMap(WindowId, Window),
    focused_window: ?WindowId = null,
    next_window_id: WindowId = 1,

    // Event callbacks
    on_window_created: ?*const fn (window: *Window) void = null,
    on_window_closed: ?*const fn (window: *Window) void = null,
    on_window_focused: ?*const fn (window: *Window) void = null,

    pub fn init(allocator: std.mem.Allocator) WindowManager {
        return .{
            .allocator = allocator,
            .windows = std.AutoHashMap(WindowId, Window).init(allocator),
        };
    }

    pub fn deinit(self: *WindowManager) void {
        var it = self.windows.valueIterator();
        while (it.next()) |window| {
            window.deinit(self.allocator);
        }
        self.windows.deinit();
    }

    /// Create a new window
    pub fn createWindow(self: *WindowManager, config: WindowConfig) !*Window {
        const id = self.next_window_id;
        self.next_window_id += 1;

        const window = Window.init(self.allocator, id, config);
        try self.windows.put(id, window);

        const window_ptr = self.windows.getPtr(id).?;

        if (self.on_window_created) |cb| {
            cb(window_ptr);
        }

        if (self.focused_window == null) {
            self.focused_window = id;
        }

        return window_ptr;
    }

    /// Destroy a window
    pub fn destroyWindow(self: *WindowManager, id: WindowId) void {
        if (self.windows.fetchRemove(id)) |kv| {
            if (self.on_window_closed) |cb| {
                cb(&kv.value);
            }
            kv.value.deinit(self.allocator);
        }

        if (self.focused_window == id) {
            self.focused_window = null;
            // Focus another window if available
            var it = self.windows.keyIterator();
            if (it.next()) |key_ptr| {
                self.focused_window = key_ptr.*;
            }
        }
    }

    /// Get a window by ID
    pub fn getWindow(self: *WindowManager, id: WindowId) ?*Window {
        return self.windows.getPtr(id);
    }

    /// Get the focused window
    pub fn getFocusedWindow(self: *WindowManager) ?*Window {
        const id = self.focused_window orelse return null;
        return self.windows.getPtr(id);
    }

    /// Set focused window
    pub fn focusWindow(self: *WindowManager, id: WindowId) void {
        if (!self.windows.contains(id)) return;

        self.focused_window = id;

        if (self.getWindow(id)) |window| {
            window.setFocused(true);
            if (self.on_window_focused) |cb| {
                cb(window);
            }
        }
    }

    /// Get window count
    pub fn windowCount(self: *const WindowManager) usize {
        return self.windows.count();
    }

    /// Check if any windows exist
    pub fn hasWindows(self: *const WindowManager) bool {
        return self.windows.count() > 0;
    }

    /// Iterate over all windows
    pub fn iter(self: *WindowManager) WindowIterator {
        return .{ .it = self.windows.valueIterator() };
    }

    pub const WindowIterator = struct {
        it: std.AutoHashMap(WindowId, Window).ValueIterator,

        pub fn next(self: *WindowIterator) ?*Window {
            return self.it.next();
        }
    };
};
