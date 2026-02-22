const std = @import("std");

// Central boundary for application-specific panel implementations.
// Main UI code should import panels via this module so extraction to a
// dedicated package can be done behind a single seam.
pub const chat = @import("chat_panel.zig");
pub const code_editor = @import("code_editor_panel.zig");
pub const tool_output = @import("tool_output_panel.zig");
pub const control = @import("control_panel.zig");
pub const connection = @import("connection_panel.zig");
pub const agents = @import("agents_panel.zig");
pub const inbox = @import("inbox_panel.zig");
pub const sessions = @import("sessions_panel.zig");
pub const settings = @import("settings_panel.zig");
pub const showcase = @import("showcase_panel.zig");
pub const workboard = @import("workboard_panel.zig");
pub const operator = @import("../operator_view.zig");
pub const approvals_inbox = @import("../approvals_inbox_view.zig");
pub const interfaces = @import("interfaces.zig");

pub fn deinit(allocator: std.mem.Allocator) void {
    agents.deinit(allocator);
}
