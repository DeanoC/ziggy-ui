const std = @import("std");

pub const FileNodeKind = enum {
    directory,
    file,
};

pub const ProjectSummary = struct {
    id: []const u8,
    name: []const u8,
    description: []const u8 = "",
    status: []const u8 = "active",
    total_files: usize = 0,
    dirty_files: usize = 0,
};

pub const ProjectStats = struct {
    directories: usize = 0,
    files: usize = 0,
    dirty_files: usize = 0,
};

pub const FileTreeNode = struct {
    project_id: []const u8,
    path: []const u8,
    name: []const u8,
    kind: FileNodeKind,
    language: ?[]const u8 = null,
    dirty: bool = false,
    size_bytes: usize = 0,
    modified_at_ms: i64 = 0,
};

pub const FileDocument = struct {
    project_id: []const u8,
    path: []const u8,
    language: ?[]const u8 = null,
    content: []const u8 = "",
};

pub const FileMatch = struct {
    project_id: []const u8,
    path: []const u8,
    line: usize = 1,
    column: usize = 1,
    snippet: []const u8,
};

pub const RecentFile = struct {
    project_id: []const u8,
    path: []const u8,
    language: ?[]const u8 = null,
    dirty: bool = false,
    modified_at_ms: i64 = 0,
};

pub const DirectoryBreadcrumb = struct {
    label: []const u8,
    path: []const u8,
};

pub const UiDataProvider = struct {
    context: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        listProjects: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror![]ProjectSummary,
        listProjectTree: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, project_id: []const u8, parent_path: []const u8, depth: usize) anyerror![]FileTreeNode,
        openFile: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, project_id: []const u8, file_path: []const u8) anyerror!FileDocument,
        searchFiles: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, project_id: []const u8, query: []const u8) anyerror![]FileMatch,
        listRecentFiles: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, project_id: []const u8) anyerror![]RecentFile,
        listBreadcrumbs: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, project_id: []const u8, path: []const u8) anyerror![]DirectoryBreadcrumb,
    };

    pub fn listProjects(self: *const UiDataProvider, allocator: std.mem.Allocator) ![]ProjectSummary {
        return self.vtable.listProjects(self.context, allocator);
    }

    pub fn listProjectTree(
        self: *const UiDataProvider,
        allocator: std.mem.Allocator,
        project_id: []const u8,
        parent_path: []const u8,
        depth: usize,
    ) ![]FileTreeNode {
        return self.vtable.listProjectTree(self.context, allocator, project_id, parent_path, depth);
    }

    pub fn openFile(
        self: *const UiDataProvider,
        allocator: std.mem.Allocator,
        project_id: []const u8,
        file_path: []const u8,
    ) !FileDocument {
        return self.vtable.openFile(self.context, allocator, project_id, file_path);
    }

    pub fn searchFiles(
        self: *const UiDataProvider,
        allocator: std.mem.Allocator,
        project_id: []const u8,
        query: []const u8,
    ) ![]FileMatch {
        return self.vtable.searchFiles(self.context, allocator, project_id, query);
    }

    pub fn listRecentFiles(
        self: *const UiDataProvider,
        allocator: std.mem.Allocator,
        project_id: []const u8,
    ) ![]RecentFile {
        return self.vtable.listRecentFiles(self.context, allocator, project_id);
    }

    pub fn listBreadcrumbs(
        self: *const UiDataProvider,
        allocator: std.mem.Allocator,
        project_id: []const u8,
        path: []const u8,
    ) ![]DirectoryBreadcrumb {
        return self.vtable.listBreadcrumbs(self.context, allocator, project_id, path);
    }
};

pub const FixtureProvider = struct {
    seed: u32 = 1,

    pub fn provider(self: *FixtureProvider) UiDataProvider {
        return .{
            .context = self,
            .vtable = &fixture_vtable,
        };
    }
};

const FixtureFile = struct {
    project_id: []const u8,
    path: []const u8,
    name: []const u8,
    kind: FileNodeKind,
    language: ?[]const u8 = null,
    dirty: bool = false,
    size_bytes: usize = 0,
    modified_at_ms: i64 = 0,
    content: []const u8 = "",
};

const fixture_projects = [_]ProjectSummary{
    .{
        .id = "workspace-main",
        .name = "Workspace Main",
        .description = "Primary desktop workspace and panel shell",
        .status = "active",
        .total_files = 14,
        .dirty_files = 2,
    },
    .{
        .id = "render-expressive",
        .name = "Expressive Rendering",
        .description = "Animation, sprite, and preview rendering modules",
        .status = "in-progress",
        .total_files = 11,
        .dirty_files = 4,
    },
    .{
        .id = "docs-fixtures",
        .name = "Fixture Contracts",
        .description = "Provider-facing fixtures for project and file views",
        .status = "draft",
        .total_files = 8,
        .dirty_files = 1,
    },
};

const fixture_files = [_]FixtureFile{
    .{ .project_id = "workspace-main", .path = "src", .name = "src", .kind = .directory, .modified_at_ms = 1_708_922_000_000 },
    .{ .project_id = "workspace-main", .path = "src/ui", .name = "ui", .kind = .directory, .modified_at_ms = 1_708_922_200_000 },
    .{ .project_id = "workspace-main", .path = "src/ui/main_window.zig", .name = "main_window.zig", .kind = .file, .language = "zig", .dirty = true, .size_bytes = 68_224, .modified_at_ms = 1_708_923_000_000, .content = "pub fn drawWindow(...) UiAction {\n    // workspace rendering entry\n}\n" },
    .{ .project_id = "workspace-main", .path = "src/ui/panel_manager.zig", .name = "panel_manager.zig", .kind = .file, .language = "zig", .size_bytes = 22_481, .modified_at_ms = 1_708_920_000_000, .content = "pub fn ensurePanel(...) void {\n    // open singleton panel\n}\n" },
    .{ .project_id = "workspace-main", .path = "src/ui/panels", .name = "panels", .kind = .directory, .modified_at_ms = 1_708_920_900_000 },
    .{ .project_id = "workspace-main", .path = "src/ui/panels/control_panel.zig", .name = "control_panel.zig", .kind = .file, .language = "zig", .dirty = true, .size_bytes = 8_710, .modified_at_ms = 1_708_924_100_000, .content = "const workspace_tabs = [_][]const u8{\"Sessions\", \"Projects\", \"Sources\"};\n" },
    .{ .project_id = "workspace-main", .path = "README.md", .name = "README.md", .kind = .file, .language = "md", .size_bytes = 5_112, .modified_at_ms = 1_708_910_100_000, .content = "# Workspace Main\n" },

    .{ .project_id = "render-expressive", .path = "src", .name = "src", .kind = .directory, .modified_at_ms = 1_708_925_200_000 },
    .{ .project_id = "render-expressive", .path = "src/ui", .name = "ui", .kind = .directory, .modified_at_ms = 1_708_925_300_000 },
    .{ .project_id = "render-expressive", .path = "src/ui/widgets", .name = "widgets", .kind = .directory, .modified_at_ms = 1_708_925_700_000 },
    .{ .project_id = "render-expressive", .path = "src/ui/widgets/flipbook.zig", .name = "flipbook.zig", .kind = .file, .language = "zig", .dirty = true, .size_bytes = 9_214, .modified_at_ms = 1_708_926_000_000, .content = "pub fn draw(...) void {\n    // render sprite clip\n}\n" },
    .{ .project_id = "render-expressive", .path = "src/ui/widgets/viewport3d.zig", .name = "viewport3d.zig", .kind = .file, .language = "zig", .dirty = true, .size_bytes = 13_882, .modified_at_ms = 1_708_926_400_000, .content = "pub fn drawViewport(...) void {\n    // project simple mesh into 2D\n}\n" },
    .{ .project_id = "render-expressive", .path = "src/ui/animation.zig", .name = "animation.zig", .kind = .file, .language = "zig", .size_bytes = 6_738, .modified_at_ms = 1_708_926_600_000, .content = "pub const Animator = struct {\n    // timeline state\n};\n" },
    .{ .project_id = "render-expressive", .path = "assets", .name = "assets", .kind = .directory, .modified_at_ms = 1_708_926_800_000 },
    .{ .project_id = "render-expressive", .path = "assets/sprites", .name = "sprites", .kind = .directory, .modified_at_ms = 1_708_926_850_000 },
    .{ .project_id = "render-expressive", .path = "assets/sprites/status_flipbook.json", .name = "status_flipbook.json", .kind = .file, .language = "json", .size_bytes = 902, .modified_at_ms = 1_708_927_000_000, .content = "{ \"clips\": [\"idle\", \"working\"] }\n" },

    .{ .project_id = "docs-fixtures", .path = "docs", .name = "docs", .kind = .directory, .modified_at_ms = 1_708_900_000_000 },
    .{ .project_id = "docs-fixtures", .path = "docs/ui_data_provider.md", .name = "ui_data_provider.md", .kind = .file, .language = "md", .size_bytes = 2_332, .modified_at_ms = 1_708_902_000_000, .content = "## UiDataProvider\nContracts for project/file view models.\n" },
    .{ .project_id = "docs-fixtures", .path = "fixtures", .name = "fixtures", .kind = .directory, .modified_at_ms = 1_708_901_000_000 },
    .{ .project_id = "docs-fixtures", .path = "fixtures/projects.json", .name = "projects.json", .kind = .file, .language = "json", .size_bytes = 1_456, .modified_at_ms = 1_708_901_500_000, .content = "{ \"projects\": [\"workspace-main\", \"render-expressive\"] }\n" },
    .{ .project_id = "docs-fixtures", .path = "fixtures/files.json", .name = "files.json", .kind = .file, .language = "json", .dirty = true, .size_bytes = 3_144, .modified_at_ms = 1_708_903_200_000, .content = "{ \"files\": [] }\n" },
};

var fixture_provider_instance = FixtureProvider{};
var active_provider: ?UiDataProvider = null;

const fixture_vtable = UiDataProvider.VTable{
    .listProjects = fixtureListProjects,
    .listProjectTree = fixtureListProjectTree,
    .openFile = fixtureOpenFile,
    .searchFiles = fixtureSearchFiles,
    .listRecentFiles = fixtureListRecentFiles,
    .listBreadcrumbs = fixtureListBreadcrumbs,
};

pub fn get() UiDataProvider {
    if (active_provider == null) {
        active_provider = fixture_provider_instance.provider();
    }
    return active_provider.?;
}

pub fn set(provider: UiDataProvider) void {
    active_provider = provider;
}

pub fn resetToFixtures() void {
    active_provider = fixture_provider_instance.provider();
}

fn fixtureListProjects(ctx: *anyopaque, allocator: std.mem.Allocator) ![]ProjectSummary {
    _ = ctx;
    return cloneSlice(ProjectSummary, allocator, fixture_projects[0..]);
}

fn fixtureListProjectTree(
    ctx: *anyopaque,
    allocator: std.mem.Allocator,
    project_id: []const u8,
    parent_path: []const u8,
    depth: usize,
) ![]FileTreeNode {
    _ = ctx;
    var matches = std.ArrayList(FileTreeNode).empty;
    defer matches.deinit(allocator);

    for (fixture_files) |entry| {
        if (!std.mem.eql(u8, entry.project_id, project_id)) continue;
        if (!isInSubtree(entry.path, parent_path)) continue;
        const rel_depth = relativeDepth(entry.path, parent_path) orelse continue;
        if (depth != 0 and rel_depth > depth) continue;

        try matches.append(allocator, .{
            .project_id = entry.project_id,
            .path = entry.path,
            .name = entry.name,
            .kind = entry.kind,
            .language = entry.language,
            .dirty = entry.dirty,
            .size_bytes = entry.size_bytes,
            .modified_at_ms = entry.modified_at_ms,
        });
    }

    if (matches.items.len == 0 and parent_path.len == 0) {
        return error.ProjectNotFound;
    }

    return try matches.toOwnedSlice(allocator);
}

fn fixtureOpenFile(
    ctx: *anyopaque,
    allocator: std.mem.Allocator,
    project_id: []const u8,
    file_path: []const u8,
) !FileDocument {
    _ = ctx;
    _ = allocator;
    for (fixture_files) |entry| {
        if (!std.mem.eql(u8, entry.project_id, project_id)) continue;
        if (!std.mem.eql(u8, entry.path, file_path)) continue;
        if (entry.kind != .file) return error.NotAFile;
        return .{
            .project_id = entry.project_id,
            .path = entry.path,
            .language = entry.language,
            .content = entry.content,
        };
    }
    return error.FileNotFound;
}

fn fixtureSearchFiles(
    ctx: *anyopaque,
    allocator: std.mem.Allocator,
    project_id: []const u8,
    query: []const u8,
) ![]FileMatch {
    _ = ctx;
    var items = std.ArrayList(FileMatch).empty;
    defer items.deinit(allocator);

    for (fixture_files) |entry| {
        if (!std.mem.eql(u8, entry.project_id, project_id)) continue;
        if (entry.kind != .file) continue;
        if (query.len > 0 and !containsIgnoreCase(entry.path, query) and !containsIgnoreCase(entry.content, query)) continue;

        try items.append(allocator, .{
            .project_id = entry.project_id,
            .path = entry.path,
            .line = 1,
            .column = 1,
            .snippet = if (entry.content.len > 0) entry.content else entry.path,
        });
    }

    return try items.toOwnedSlice(allocator);
}

fn fixtureListRecentFiles(
    ctx: *anyopaque,
    allocator: std.mem.Allocator,
    project_id: []const u8,
) ![]RecentFile {
    _ = ctx;
    var out = std.ArrayList(RecentFile).empty;
    defer out.deinit(allocator);

    for (fixture_files) |entry| {
        if (!std.mem.eql(u8, entry.project_id, project_id)) continue;
        if (entry.kind != .file) continue;
        try out.append(allocator, .{
            .project_id = entry.project_id,
            .path = entry.path,
            .language = entry.language,
            .dirty = entry.dirty,
            .modified_at_ms = entry.modified_at_ms,
        });
        if (out.items.len >= 8) break;
    }

    std.mem.sort(RecentFile, out.items, {}, recentFileDescByTime);
    return try out.toOwnedSlice(allocator);
}

fn fixtureListBreadcrumbs(
    ctx: *anyopaque,
    allocator: std.mem.Allocator,
    project_id: []const u8,
    path: []const u8,
) ![]DirectoryBreadcrumb {
    _ = ctx;
    _ = project_id;
    if (path.len == 0) {
        return allocator.alloc(DirectoryBreadcrumb, 0);
    }

    var parts = std.mem.splitScalar(u8, path, '/');
    var count: usize = 0;
    while (parts.next()) |_| count += 1;

    if (count == 0) return allocator.alloc(DirectoryBreadcrumb, 0);

    var out = try allocator.alloc(DirectoryBreadcrumb, count);
    var prefix_len: usize = 0;
    var idx: usize = 0;
    parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| : (idx += 1) {
        if (idx > 0) {
            while (prefix_len < path.len and path[prefix_len] != '/') : (prefix_len += 1) {}
            prefix_len += 1;
        }
        const next_slash = std.mem.indexOfScalarPos(u8, path, prefix_len, '/') orelse path.len;
        const crumb_path = path[0..next_slash];
        out[idx] = .{
            .label = part,
            .path = crumb_path,
        };
        prefix_len = next_slash;
    }
    return out;
}

fn cloneSlice(comptime T: type, allocator: std.mem.Allocator, source: []const T) ![]T {
    const out = try allocator.alloc(T, source.len);
    @memcpy(out, source);
    return out;
}

fn recentFileDescByTime(_: void, lhs: RecentFile, rhs: RecentFile) bool {
    return lhs.modified_at_ms > rhs.modified_at_ms;
}

fn isInSubtree(path: []const u8, parent_path: []const u8) bool {
    if (parent_path.len == 0) return true;
    if (std.mem.eql(u8, path, parent_path)) return true;
    if (!std.mem.startsWith(u8, path, parent_path)) return false;
    return path.len > parent_path.len and path[parent_path.len] == '/';
}

fn relativeDepth(path: []const u8, parent_path: []const u8) ?usize {
    if (!isInSubtree(path, parent_path)) return null;
    if (std.mem.eql(u8, path, parent_path)) return 0;

    const start = if (parent_path.len == 0) 0 else parent_path.len + 1;
    if (start >= path.len) return 0;
    return componentCount(path[start..]);
}

fn componentCount(path: []const u8) usize {
    if (path.len == 0) return 0;
    var count: usize = 1;
    for (path) |ch| {
        if (ch == '/') count += 1;
    }
    return count;
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var match = true;
        var j: usize = 0;
        while (j < needle.len) : (j += 1) {
            if (std.ascii.toLower(haystack[i + j]) != std.ascii.toLower(needle[j])) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}

test "fixture provider lists projects and project tree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var provider = get();
    const projects = try provider.listProjects(alloc);
    try std.testing.expect(projects.len >= 3);
    try std.testing.expectEqualStrings("workspace-main", projects[0].id);

    const tree = try provider.listProjectTree(alloc, "workspace-main", "", 1);
    try std.testing.expect(tree.len > 0);
    try std.testing.expectEqual(FileNodeKind.directory, tree[0].kind);
}

test "fixture provider search and breadcrumbs" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var provider = get();
    const matches = try provider.searchFiles(alloc, "render-expressive", "flipbook");
    try std.testing.expect(matches.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, matches[0].path, "flipbook") != null);

    const crumbs = try provider.listBreadcrumbs(alloc, "render-expressive", "assets/sprites/status_flipbook.json");
    try std.testing.expectEqual(@as(usize, 3), crumbs.len);
    try std.testing.expectEqualStrings("assets", crumbs[0].label);
}
