//! Dock detach/reattach functionality
const std = @import("std");
const DockGraph = @import("dock_graph.zig");

/// Detached panel info
pub const DetachedPanel = struct {
    panel_id: DockGraph.DockNodeId,
    window_x: i32,
    window_y: i32,
    window_width: u32,
    window_height: u32,
    is_minimized: bool = false,
    is_maximized: bool = false,
};

/// Detach manager for multi-window support
pub const DetachManager = struct {
    allocator: std.mem.Allocator,
    detached_panels: std.ArrayList(DetachedPanel),

    pub fn init(allocator: std.mem.Allocator) DetachManager {
        return .{
            .allocator = allocator,
            .detached_panels = std.ArrayList(DetachedPanel).init(allocator),
        };
    }

    pub fn deinit(self: *DetachManager) void {
        self.detached_panels.deinit();
    }

    /// Detach a panel
    pub fn detachPanel(
        self: *DetachManager,
        panel_id: DockGraph.DockNodeId,
        x: i32,
        y: i32,
        width: u32,
        height: u32,
    ) !void {
        // Check if already detached
        for (self.detached_panels.items) |panel| {
            if (panel.panel_id == panel_id) return error.AlreadyDetached;
        }

        try self.detached_panels.append(.{
            .panel_id = panel_id,
            .window_x = x,
            .window_y = y,
            .window_width = width,
            .window_height = height,
        });
    }

    /// Reattach a panel
    pub fn reattachPanel(self: *DetachManager, panel_id: DockGraph.DockNodeId) ?DetachedPanel {
        for (self.detached_panels.items, 0..) |panel, i| {
            if (panel.panel_id == panel_id) {
                return self.detached_panels.orderedRemove(i);
            }
        }
        return null;
    }

    /// Get detached panel info
    pub fn getDetachedPanel(self: *const DetachManager, panel_id: DockGraph.DockNodeId) ?DetachedPanel {
        for (self.detached_panels.items) |panel| {
            if (panel.panel_id == panel_id) return panel;
        }
        return null;
    }

    /// Update window position/size for a detached panel
    pub fn updatePanelWindow(
        self: *DetachManager,
        panel_id: DockGraph.DockNodeId,
        x: i32,
        y: i32,
        width: u32,
        height: u32,
    ) void {
        for (self.detached_panels.items) |*panel| {
            if (panel.panel_id == panel_id) {
                panel.window_x = x;
                panel.window_y = y;
                panel.window_width = width;
                panel.window_height = height;
                return;
            }
        }
    }
};
