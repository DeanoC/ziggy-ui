//! Base widget types
const std = @import("std");

/// Widget base interface
pub const Widget = struct {
    /// Widget ID
    id: u64,

    /// Widget rectangle
    rect: Rect,

    /// User data
    userdata: ?*anyopaque = null,

    /// Event callback
    on_event: ?*const fn (*Widget, Event) void = null,

    /// Draw callback
    draw: ?*const fn (*Widget, *DrawContext) void = null,

    pub const Rect = struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,

        pub fn contains(self: Rect, point: [2]f32) bool {
            return point[0] >= self.x and
                point[0] <= self.x + self.width and
                point[1] >= self.y and
                point[1] <= self.y + self.height;
        }
    };

    pub const Event = union(enum) {
        mouse_enter,
        mouse_leave,
        mouse_down: [2]f32,
        mouse_up: [2]f32,
        mouse_move: [2]f32,
        click: [2]f32,
        focus,
        blur,
        key_down: @import("../input/input_state.zig").Key,
        key_up: @import("../input/input_state.zig").Key,
        char_input: u32,
    };

    pub const DrawContext = struct {
        allocator: std.mem.Allocator,
        // Would contain render command list, theme, etc.
    };
};
