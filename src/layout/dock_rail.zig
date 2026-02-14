//! Dock rail for quick panel access
const std = @import("std");
const DockGraph = @import("dock_graph.zig");

/// Rail position
pub const RailPosition = enum {
    left,
    right,
    top,
    bottom,
};

/// Dock rail item
pub const RailItem = struct {
    id: []const u8,
    icon: []const u8, // Unicode icon or label
    tooltip: []const u8 = "",
    is_pinned: bool = false,
    is_active: bool = false,
};

/// Dock rail state
pub const DockRail = struct {
    allocator: std.mem.Allocator,
    position: RailPosition,
    items: std.ArrayList(RailItem),
    width: f32 = 48.0,
    expanded: bool = false,
    expanded_width: f32 = 200.0,
    hovered_item: ?usize = null,

    pub fn init(allocator: std.mem.Allocator, position: RailPosition) DockRail {
        return .{
            .allocator = allocator,
            .position = position,
            .items = std.ArrayList(RailItem).init(allocator),
        };
    }

    pub fn deinit(self: *DockRail) void {
        self.items.deinit();
    }

    /// Add an item to the rail
    pub fn addItem(self: *DockRail, item: RailItem) !void {
        try self.items.append(item);
    }

    /// Remove an item by ID
    pub fn removeItem(self: *DockRail, id: []const u8) void {
        for (self.items.items, 0..) |item, i| {
            if (std.mem.eql(u8, item.id, id)) {
                _ = self.items.orderedRemove(i);
                return;
            }
        }
    }

    /// Toggle item active state
    pub fn toggleItem(self: *DockRail, index: usize) void {
        if (index < self.items.items.len) {
            self.items.items[index].is_active = !self.items.items[index].is_active;
        }
    }

    /// Get rail rectangle
    pub fn getRect(self: *const DockRail, container_width: f32, container_height: f32) struct { x: f32, y: f32, width: f32, height: f32 } {
        const actual_width = if (self.expanded) self.expanded_width else self.width;
        
        return switch (self.position) {
            .left => .{ .x = 0, .y = 0, .width = actual_width, .height = container_height },
            .right => .{ .x = container_width - actual_width, .y = 0, .width = actual_width, .height = container_height },
            .top => .{ .x = 0, .y = 0, .width = container_width, .height = actual_width },
            .bottom => .{ .x = 0, .y = container_height - actual_width, .width = container_width, .height = actual_width },
        };
    }

    /// Get item rectangle at index
    pub fn getItemRect(self: *const DockRail, index: usize) ?struct { x: f32, y: f32, size: f32 } {
        if (index >= self.items.items.len) return null;
        
        const size = self.width - 8.0; // Padding
        const padding = 4.0;
        
        const x = padding;
        const y = padding + @as(f32, @floatFromInt(index)) * (size + padding);
        
        return .{ .x = x, .y = y, .size = size };
    }

    /// Handle mouse position
    pub fn updateHover(self: *DockRail, mouse_pos: [2]f32, container_width: f32, container_height: f32) void {
        const rail_rect = self.getRect(container_width, container_height);
        
        if (mouse_pos[0] < rail_rect.x or 
            mouse_pos[0] > rail_rect.x + rail_rect.width or
            mouse_pos[1] < rail_rect.y or 
            mouse_pos[1] > rail_rect.y + rail_rect.height) {
            self.hovered_item = null;
            return;
        }
        
        // Find hovered item
        const local_y = mouse_pos[1] - rail_rect.y;
        const size = self.width - 8.0;
        const padding = 4.0;
        const index = @as(usize, @intFromFloat(@floor((local_y - padding) / (size + padding))));
        
        if (index < self.items.items.len) {
            self.hovered_item = index;
        } else {
            self.hovered_item = null;
        }
    }
};
