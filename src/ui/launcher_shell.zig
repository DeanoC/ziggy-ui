const contracts = @import("ziggy-ui-panels");

const has_launcher = @hasDecl(contracts, "launcher");

pub const ConnectionProfileModel = if (has_launcher)
    contracts.launcher.ConnectionProfileModel
else
    struct {
        id: []const u8,
        name: []const u8,
        server_url: []const u8,
    };

pub const ProjectCardModel = if (has_launcher)
    contracts.launcher.ProjectCardModel
else
    struct {
        id: []const u8,
        name: []const u8,
        status: []const u8,
    };

pub const LauncherViewModel = if (has_launcher)
    contracts.launcher.LauncherViewModel
else
    struct {
        connected: bool = false,
        selected_profile_id: ?[]const u8 = null,
        selected_project_id: ?[]const u8 = null,
        profiles: []const ConnectionProfileModel = &.{},
        projects: []const ProjectCardModel = &.{},
    };

pub const LauncherAction = if (has_launcher)
    contracts.launcher.LauncherAction
else
    union(enum) {
        none,
    };

pub fn canOpenSelectedProject(view: *const LauncherViewModel) bool {
    return view.connected and view.selected_profile_id != null and view.selected_project_id != null;
}
