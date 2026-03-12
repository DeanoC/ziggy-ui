// Shared IDE menu contracts for workspace-first hosts.
pub const IdeMenuDomain = enum {
    file,
    edit,
    view,
    workspace,
    tools,
    window,
    help,
};

pub const IdeMenuAction = enum {
    file_new_workspace,
    file_open_workspace,
    file_switch_workspace,
    edit_undo,
    edit_redo,
    view_toggle_chat,
    view_toggle_explorer,
    workspace_refresh,
    tools_open_settings,
    window_new_window,
    help_about,
};

pub const IdeMenuItem = struct {
    domain: IdeMenuDomain,
    action: IdeMenuAction,
    label: []const u8,
    enabled: bool = true,
};

pub const IdeMenuModel = struct {
    items: []const IdeMenuItem = &.{},
};

pub fn defaultMenu() []const IdeMenuItem {
    return &[_]IdeMenuItem{
        .{ .domain = .file, .action = .file_new_workspace, .label = "New Workspace" },
        .{ .domain = .file, .action = .file_open_workspace, .label = "Open Workspace" },
        .{ .domain = .file, .action = .file_switch_workspace, .label = "Switch Workspace" },
        .{ .domain = .edit, .action = .edit_undo, .label = "Undo" },
        .{ .domain = .edit, .action = .edit_redo, .label = "Redo" },
        .{ .domain = .view, .action = .view_toggle_chat, .label = "Chat" },
        .{ .domain = .view, .action = .view_toggle_explorer, .label = "Explorer" },
        .{ .domain = .workspace, .action = .workspace_refresh, .label = "Refresh Workspace" },
        .{ .domain = .tools, .action = .tools_open_settings, .label = "Settings" },
        .{ .domain = .window, .action = .window_new_window, .label = "New Window" },
        .{ .domain = .help, .action = .help_about, .label = "About" },
    };
}
