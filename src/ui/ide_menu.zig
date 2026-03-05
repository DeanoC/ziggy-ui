const contracts = @import("ziggy-ui-panels");

const has_ide_menu = @hasDecl(contracts, "ide_menu");

pub const IdeMenuDomain = if (has_ide_menu)
    contracts.ide_menu.IdeMenuDomain
else
    enum {
        file,
        edit,
        view,
        project,
        tools,
        window,
        help,
    };

pub const IdeMenuAction = if (has_ide_menu)
    contracts.ide_menu.IdeMenuAction
else
    enum {
        file_new_project,
        file_open_project,
        file_switch_project,
        edit_undo,
        edit_redo,
        view_toggle_chat,
        view_toggle_explorer,
        project_refresh,
        tools_open_settings,
        window_new_window,
        help_about,
    };

pub const IdeMenuItem = if (has_ide_menu)
    contracts.ide_menu.IdeMenuItem
else
    struct {
        domain: IdeMenuDomain,
        action: IdeMenuAction,
        label: []const u8,
        enabled: bool = true,
    };

pub const IdeMenuModel = if (has_ide_menu)
    contracts.ide_menu.IdeMenuModel
else
    struct {
        items: []const IdeMenuItem = &.{},
    };

pub fn defaultMenu() []const IdeMenuItem {
    return &[_]IdeMenuItem{
        .{ .domain = .file, .action = .file_new_project, .label = "New Project" },
        .{ .domain = .file, .action = .file_open_project, .label = "Open Project" },
        .{ .domain = .file, .action = .file_switch_project, .label = "Switch Project" },
        .{ .domain = .edit, .action = .edit_undo, .label = "Undo" },
        .{ .domain = .edit, .action = .edit_redo, .label = "Redo" },
        .{ .domain = .view, .action = .view_toggle_chat, .label = "Chat" },
        .{ .domain = .view, .action = .view_toggle_explorer, .label = "Explorer" },
        .{ .domain = .project, .action = .project_refresh, .label = "Refresh" },
        .{ .domain = .tools, .action = .tools_open_settings, .label = "Settings" },
        .{ .domain = .window, .action = .window_new_window, .label = "New Window" },
        .{ .domain = .help, .action = .help_about, .label = "About" },
    };
}
