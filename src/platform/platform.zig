//! Platform abstraction layer
const std = @import("std");
const Window = @import("../window/window.zig").Window;
const WindowConfig = @import("../window/window.zig").WindowConfig;
const WindowId = @import("../window/window.zig").WindowId;
const Event = @import("../core/events.zig").Event;

/// Platform capabilities
pub const Capabilities = struct {
    multiple_windows: bool = false,
    drag_and_drop: bool = false,
    clipboard: bool = false,
    file_dialogs: bool = false,
    high_dpi: bool = false,
    vsync_control: bool = false,
};

/// Platform backend interface
pub const PlatformBackend = struct {
    /// Initialize the platform
    init: *const fn () anyerror!void,

    /// Shutdown the platform
    deinit: *const fn () void,

    /// Get capabilities
    getCapabilities: *const fn () Capabilities,

    /// Create a window
    createWindow: *const fn (config: WindowConfig, userdata: ?*anyopaque) anyerror!WindowId,

    /// Destroy a window
    destroyWindow: *const fn (window_id: WindowId) void,

    /// Show a window
    showWindow: *const fn (window_id: WindowId) void,

    /// Hide a window
    hideWindow: *const fn (window_id: WindowId) void,

    /// Set window title
    setWindowTitle: *const fn (window_id: WindowId, title: []const u8) void,

    /// Set window size
    setWindowSize: *const fn (window_id: WindowId, width: u32, height: u32) void,

    /// Set window position
    setWindowPosition: *const fn (window_id: WindowId, x: i32, y: i32) void,

    /// Set window mode (fullscreen, etc.)
    setWindowMode: *const fn (window_id: WindowId, mode: @import("../window/window.zig").WindowMode) void,

    /// Get window size
    getWindowSize: *const fn (window_id: WindowId) struct { width: u32, height: u32 },

    /// Get window framebuffer size (may differ from window size on high-DPI)
    getFramebufferSize: *const fn (window_id: WindowId) struct { width: u32, height: u32 },

    /// Get window content scale (for high-DPI)
    getWindowContentScale: *const fn (window_id: WindowId) struct { x: f32, y: f32 },

    /// Request window attention
    requestWindowAttention: *const fn (window_id: WindowId) void,

    /// Poll for events (returns true if an event was retrieved)
    pollEvent: *const fn (event: *Event) bool,

    /// Wait for events (blocks until an event is available)
    waitEvent: *const fn (event: *Event) void,

    /// Get current time in seconds
    getTime: *const fn () f64,

    /// Sleep for a duration in seconds
    sleep: *const fn (seconds: f64) void,

    /// Get clipboard text
    getClipboardText: *const fn (allocator: std.mem.Allocator) ?[]const u8,

    /// Set clipboard text
    setClipboardText: *const fn (text: []const u8) void,

    /// Get primary monitor info
    getPrimaryMonitor: *const fn () ?MonitorInfo,

    /// Get all monitors
    getMonitors: *const fn (allocator: std.mem.Allocator) anyerror![]MonitorInfo,
};

/// Monitor information
pub const MonitorInfo = struct {
    name: []const u8,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    scale_x: f32,
    scale_y: f32,
    refresh_rate: u32,

    pub fn deinit(self: *MonitorInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

/// Platform instance
pub const Platform = struct {
    backend: PlatformBackend,
    allocator: std.mem.Allocator,

    // Event queue for buffering
    event_queue: EventQueue,

    pub const EventQueue = struct {
        events: std.ArrayList(Event),

        pub fn init(allocator: std.mem.Allocator) EventQueue {
            _ = allocator;
            return .{
                .events = .empty,
            };
        }

        pub fn deinit(self: *EventQueue, allocator: std.mem.Allocator) void {
            self.events.deinit(allocator);
        }

        pub fn push(self: *EventQueue, allocator: std.mem.Allocator, event: Event) !void {
            try self.events.append(allocator, event);
        }

        pub fn pop(self: *EventQueue) ?Event {
            if (self.events.items.len == 0) return null;
            return self.events.orderedRemove(0);
        }
    };

    pub fn init(backend: PlatformBackend, allocator: std.mem.Allocator) !Platform {
        try backend.init();
        return .{
            .backend = backend,
            .allocator = allocator,
            .event_queue = EventQueue.init(allocator),
        };
    }

    pub fn deinit(self: *Platform) void {
        self.event_queue.deinit(self.allocator);
        self.backend.deinit();
    }

    pub fn getCapabilities(self: *Platform) Capabilities {
        return self.backend.getCapabilities();
    }

    pub fn createWindow(self: *Platform, config: WindowConfig, userdata: ?*anyopaque) !WindowId {
        return try self.backend.createWindow(config, userdata);
    }

    pub fn destroyWindow(self: *Platform, window_id: WindowId) void {
        self.backend.destroyWindow(window_id);
    }

    pub fn showWindow(self: *Platform, window_id: WindowId) void {
        self.backend.showWindow(window_id);
    }

    pub fn hideWindow(self: *Platform, window_id: WindowId) void {
        self.backend.hideWindow(window_id);
    }

    pub fn setWindowTitle(self: *Platform, window_id: WindowId, title: []const u8) void {
        self.backend.setWindowTitle(window_id, title);
    }

    pub fn setWindowSize(self: *Platform, window_id: WindowId, width: u32, height: u32) void {
        self.backend.setWindowSize(window_id, width, height);
    }

    pub fn setWindowPosition(self: *Platform, window_id: WindowId, x: i32, y: i32) void {
        self.backend.setWindowPosition(window_id, x, y);
    }

    pub fn setWindowMode(self: *Platform, window_id: WindowId, mode: @import("../window/window.zig").WindowMode) void {
        self.backend.setWindowMode(window_id, mode);
    }

    pub fn getWindowSize(self: *Platform, window_id: WindowId) struct { width: u32, height: u32 } {
        return self.backend.getWindowSize(window_id);
    }

    pub fn getFramebufferSize(self: *Platform, window_id: WindowId) struct { width: u32, height: u32 } {
        return self.backend.getFramebufferSize(window_id);
    }

    pub fn getWindowContentScale(self: *Platform, window_id: WindowId) struct { x: f32, y: f32 } {
        return self.backend.getWindowContentScale(window_id);
    }

    pub fn requestWindowAttention(self: *Platform, window_id: WindowId) void {
        self.backend.requestWindowAttention(window_id);
    }

    pub fn pollEvents(self: *Platform) !void {
        var event: Event = undefined;
        while (self.backend.pollEvent(&event)) {
            try self.event_queue.push(self.allocator, event);
        }
    }

    pub fn waitEvent(self: *Platform) ?Event {
        var event: Event = undefined;
        if (self.event_queue.pop()) |e| {
            return e;
        }
        self.backend.waitEvent(&event);
        return event;
    }

    pub fn getNextEvent(self: *Platform) ?Event {
        return self.event_queue.pop();
    }

    pub fn getTime(self: *Platform) f64 {
        return self.backend.getTime();
    }

    pub fn sleep(self: *Platform, seconds: f64) void {
        self.backend.sleep(seconds);
    }

    pub fn getClipboardText(self: *Platform) ?[]const u8 {
        return self.backend.getClipboardText(self.allocator);
    }

    pub fn setClipboardText(self: *Platform, text: []const u8) void {
        self.backend.setClipboardText(text);
    }

    pub fn getPrimaryMonitor(self: *Platform) ?MonitorInfo {
        return self.backend.getPrimaryMonitor();
    }

    pub fn getMonitors(self: *Platform) ![]MonitorInfo {
        return try self.backend.getMonitors(self.allocator);
    }
};
