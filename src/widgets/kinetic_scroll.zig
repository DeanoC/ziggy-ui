//! Kinetic scroll widget
const std = @import("std");

/// Kinetic scroll state
pub const KineticScroll = struct {
    velocity: [2]f32 = .{ 0, 0 },
    position: [2]f32 = .{ 0, 0 },
    last_delta: [2]f32 = .{ 0, 0 },
    is_dragging: bool = false,
    drag_start_pos: [2]f32 = .{ 0, 0 },
    drag_start_scroll: [2]f32 = .{ 0, 0 },

    // Configuration
    friction: f32 = 0.9,
    min_velocity: f32 = 1.0,

    /// Start dragging
    pub fn startDrag(self: *KineticScroll, pos: [2]f32) void {
        self.is_dragging = true;
        self.drag_start_pos = pos;
        self.drag_start_scroll = self.position;
        self.velocity = .{ 0, 0 };
    }

    /// Update during drag
    pub fn updateDrag(self: *KineticScroll, pos: [2]f32) void {
        if (!self.is_dragging) return;
        
        const delta = [2]f32{
            pos[0] - self.drag_start_pos[0],
            pos[1] - self.drag_start_pos[1],
        };
        
        self.last_delta = delta;
        self.position = .{
            self.drag_start_scroll[0] + delta[0],
            self.drag_start_scroll[1] + delta[1],
        };
    }

    /// End dragging and start kinetic motion
    pub fn endDrag(self: *KineticScroll) void {
        if (!self.is_dragging) return;
        
        self.is_dragging = false;
        self.velocity = self.last_delta;
    }

    /// Update kinetic motion (call each frame)
    pub fn update(self: *KineticScroll, dt: f32) void {
        if (self.is_dragging) return;
        
        // Apply friction
        self.velocity[0] *= self.friction;
        self.velocity[1] *= self.friction;
        
        // Stop if below threshold
        if (@abs(self.velocity[0]) < self.min_velocity) self.velocity[0] = 0;
        if (@abs(self.velocity[1]) < self.min_velocity) self.velocity[1] = 0;
        
        // Update position
        self.position[0] += self.velocity[0] * dt * 60.0; // Normalize to 60fps
        self.position[1] += self.velocity[1] * dt * 60.0;
    }

    /// Clamp scroll position to content bounds
    pub fn clampToBounds(self: *KineticScroll, content_size: [2]f32, viewport_size: [2]f32) void {
        const max_scroll_x = @max(0, content_size[0] - viewport_size[0]);
        const max_scroll_y = @max(0, content_size[1] - viewport_size[1]);
        
        self.position[0] = std.math.clamp(self.position[0], -max_scroll_x, 0);
        self.position[1] = std.math.clamp(self.position[1], -max_scroll_y, 0);
    }
};
