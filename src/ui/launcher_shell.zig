// Compatibility shim for legacy launcher-shell consumers.
pub const ConnectionProfileModel = struct {
    id: []const u8,
    name: []const u8,
    server_url: []const u8,
};

pub const ProjectCardModel = struct {
    id: []const u8,
    name: []const u8,
    status: []const u8,
};

pub const LauncherViewModel = struct {
    connected: bool = false,
    selected_profile_id: ?[]const u8 = null,
    selected_project_id: ?[]const u8 = null,
    profiles: []const ConnectionProfileModel = &.{},
    projects: []const ProjectCardModel = &.{},
};

pub const LauncherAction = union(enum) {
    none,
};

pub fn canOpenSelectedProject(view: *const LauncherViewModel) bool {
    return view.connected and view.selected_profile_id != null and view.selected_project_id != null;
}
