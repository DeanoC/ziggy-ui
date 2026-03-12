// Shared launcher-shell contracts for workspace-first hosts.
pub const ConnectionProfileModel = struct {
    id: []const u8,
    name: []const u8,
    server_url: []const u8,
};

pub const WorkspaceCardModel = struct {
    id: []const u8,
    name: []const u8,
    status: []const u8,
};

pub const LauncherViewModel = struct {
    connected: bool = false,
    selected_profile_id: ?[]const u8 = null,
    selected_workspace_id: ?[]const u8 = null,
    profiles: []const ConnectionProfileModel = &.{},
    workspaces: []const WorkspaceCardModel = &.{},
};

pub const LauncherAction = union(enum) {
    none,
};

pub fn canOpenSelectedWorkspace(view: *const LauncherViewModel) bool {
    return view.connected and view.selected_profile_id != null and view.selected_workspace_id != null;
}
