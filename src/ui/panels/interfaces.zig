const workspace = @import("../workspace.zig");
const dock_graph = @import("../layout/dock_graph.zig");
const operator_view = @import("../operator_view.zig");
const agents_panel = @import("agents_panel.zig");
const std = @import("std");

pub const AttachmentOpen = struct {
    name: []u8,
    kind: []u8,
    url: []u8,
    role: []u8,
    timestamp: i64,
    body: ?[]u8 = null,
    status: ?[]u8 = null,
    truncated: bool = false,

    pub fn deinit(self: *AttachmentOpen, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.kind);
        allocator.free(self.url);
        allocator.free(self.role);
        if (self.body) |value| allocator.free(value);
        if (self.status) |value| allocator.free(value);
        self.* = undefined;
    }
};

pub const SendMessageAction = struct {
    session_key: []u8,
    message: []u8,
};

pub const UiAction = struct {
    send_message: ?SendMessageAction = null,
    connect: bool = false,
    disconnect: bool = false,
    save_config: bool = false,
    reload_theme_pack: bool = false,
    browse_theme_pack: bool = false,
    browse_theme_pack_override: bool = false,
    clear_theme_pack_override: bool = false,
    reload_theme_pack_override: bool = false,
    clear_saved: bool = false,
    config_updated: bool = false,
    spawn_window: bool = false,
    spawn_window_template: ?u32 = null,
    refresh_sessions: bool = false,
    new_session: bool = false,
    new_chat_session_key: ?[]u8 = null,
    select_session: ?[]u8 = null,
    select_session_id: ?[]u8 = null,
    new_chat_agent_id: ?[]u8 = null,
    open_session: ?agents_panel.AgentSessionAction = null,
    set_default_session: ?agents_panel.AgentSessionAction = null,
    delete_session: ?[]u8 = null,
    add_agent: ?agents_panel.AddAgentAction = null,
    remove_agent_id: ?[]u8 = null,
    open_agent_file: ?agents_panel.AgentFileOpenAction = null,
    focus_session: ?[]u8 = null,
    check_updates: bool = false,
    open_release: bool = false,
    download_update: bool = false,
    open_download: bool = false,
    install_update: bool = false,

    node_profile_apply_client: bool = false,
    node_profile_apply_service: bool = false,
    node_profile_apply_session: bool = false,

    // Windows node runner helpers (SCM service)
    node_service_install_onlogon: bool = false,
    node_service_start: bool = false,
    node_service_stop: bool = false,
    node_service_status: bool = false,
    node_service_uninstall: bool = false,
    open_node_logs: bool = false,

    refresh_nodes: bool = false,
    refresh_workboard: bool = false,
    select_node: ?[]u8 = null,
    invoke_node: ?operator_view.NodeInvokeAction = null,
    describe_node: ?[]u8 = null,
    resolve_approval: ?operator_view.ExecApprovalResolveAction = null,
    clear_node_describe: ?[]u8 = null,
    clear_node_result: bool = false,
    clear_operator_notice: bool = false,
    save_workspace: bool = false,
    detach_panel_id: ?workspace.PanelId = null,
    detach_group_node_id: ?dock_graph.NodeId = null,
    // When non-null, the UI already removed the panel from the source manager; the native loop
    // should create the tear-off window from this panel and then free the pointer.
    detach_panel: ?*workspace.Panel = null,
    open_url: ?[]u8 = null,
};

pub const DrawResult = struct {
    session_key: ?[]const u8 = null,
    agent_id: ?[]const u8 = null,
};

// Canonical action surface for host integrations that wrap the generic chat UI.
pub const ChatPanelAction = struct {
    send_message: ?[]u8 = null,
    select_session: ?[]u8 = null,
    select_session_id: ?[]u8 = null,
    new_chat_session_key: ?[]u8 = null,
    open_activity_panel: bool = false,
    open_approvals_panel: bool = false,
};

pub const FilesystemEntryKind = enum {
    unknown,
    directory,
    file,
};

pub const FilesystemSortKey = enum {
    name,
    type,
    modified,
    size,
};

pub const FilesystemSortDirection = enum {
    ascending,
    descending,
};

pub const FilesystemPreviewMode = enum {
    empty,
    text,
    json,
    unsupported,
    loading,
};

pub const FilesystemPanelModel = struct {
    connected: bool = false,
    busy: bool = false,
    sort_key: FilesystemSortKey = .name,
    sort_direction: FilesystemSortDirection = .ascending,
    hide_hidden: bool = false,
    hide_directories: bool = false,
    hide_files: bool = false,
    hide_runtime_noise: bool = false,
    total_entry_count: usize = 0,
    visible_entry_count: usize = 0,
    has_selected_entry: bool = false,

    pub fn controlsDisabled(self: FilesystemPanelModel) bool {
        return !self.connected or self.busy;
    }

    pub fn hasActiveFilters(self: FilesystemPanelModel) bool {
        return self.hide_hidden or self.hide_directories or self.hide_files or self.hide_runtime_noise;
    }

    pub fn canOpenSelectedEntry(self: FilesystemPanelModel) bool {
        return self.connected and !self.busy and self.has_selected_entry;
    }
};

pub const FilesystemRuntimeReadTarget = enum {
    status,
    health,
    metrics,
    config,
};

pub const FilesystemRuntimeControlTarget = enum {
    enable,
    disable,
    restart,
    reset,
    invoke,
};

pub const FilesystemPanelAction = union(enum) {
    refresh,
    navigate_up,
    use_workspace_root,
    select_entry_index: usize,
    open_entry_index: usize,
    open_selected_entry,
    set_sort_key: FilesystemSortKey,
    toggle_sort_direction,
    toggle_hide_hidden,
    toggle_hide_directories,
    toggle_hide_files,
    toggle_hide_runtime_noise,
    reset_explorer_view,
    refresh_preview,
};

pub const FilesystemEntryView = struct {
    index: usize = 0,
    name: []const u8,
    path: []const u8,
    kind: FilesystemEntryKind = .unknown,
    type_label: []const u8 = "unknown",
    hidden: bool = false,
    size_bytes: ?u64 = null,
    size_label: ?[]const u8 = null,
    modified_unix_ms: ?i64 = null,
    modified_label: ?[]const u8 = null,
    badge: ?[]const u8 = null,
    previewable: bool = false,
    selected: bool = false,
};

pub const FilesystemPanelView = struct {
    path_label: []const u8 = "/",
    error_text: ?[]const u8 = null,
    entries: []const FilesystemEntryView = &.{},
    total_entry_count: usize = 0,
    visible_entry_count: usize = 0,
    preview_title: []const u8 = "(select a file to preview)",
    preview_path: ?[]const u8 = null,
    preview_kind: FilesystemEntryKind = .unknown,
    preview_type_label: []const u8 = "unknown",
    preview_size_bytes: ?u64 = null,
    preview_size_label: ?[]const u8 = null,
    preview_modified_unix_ms: ?i64 = null,
    preview_modified_label: ?[]const u8 = null,
    preview_mode: FilesystemPreviewMode = .empty,
    preview_status: ?[]const u8 = null,
    preview_text: ?[]const u8 = null,
};

pub const FilesystemToolsPanelModel = struct {
    connected: bool = false,
    busy: bool = false,
    has_service_runtime_root: bool = false,
    has_selected_contract_service: bool = false,
    contract_service_count: usize = 0,

    pub fn controlsDisabled(self: FilesystemToolsPanelModel) bool {
        return !self.connected or self.busy;
    }

    pub fn hasContractPager(self: FilesystemToolsPanelModel) bool {
        return self.contract_service_count > 1;
    }
};

pub const FilesystemToolsPanelAction = union(enum) {
    runtime_read: FilesystemRuntimeReadTarget,
    runtime_control: FilesystemRuntimeControlTarget,
    contract_refresh,
    contract_select_prev,
    contract_select_next,
    contract_open_service_dir,
    contract_invoke,
    contract_read_status,
    contract_read_result,
    contract_read_help,
    contract_read_schema,
    contract_use_template,
};

pub const FilesystemToolsPanelView = struct {
    selected_contract_label: []const u8 = "Selected: (none loaded)",
    contract_payload: []const u8 = "",
};

pub const DebugPanelModel = struct {
    connected: bool = false,
    stream_enabled: bool = false,
    has_perf_history: bool = false,
    perf_benchmark_active: bool = false,
    has_perf_benchmark_capture: bool = false,
    node_watch_enabled: bool = false,
    has_search_filter: bool = false,
    has_selected_event: bool = false,
    has_selected_node_event: bool = false,
    has_diff_base_or_preview: bool = false,
    can_generate_diff: bool = false,

    pub fn canRefreshSnapshot(self: DebugPanelModel) bool {
        return self.connected and self.stream_enabled;
    }

    pub fn canRefreshNodeFeed(self: DebugPanelModel) bool {
        return self.connected;
    }

    pub fn canPauseNodeFeed(self: DebugPanelModel) bool {
        return self.connected and self.node_watch_enabled;
    }
};

pub const DebugPanelView = struct {
    title: []const u8 = "Debug Stream",
    stream_status: []const u8 = "Status: paused",
    snapshot_status: []const u8 = "Snapshot: none",
    perf_summary: []const u8 = "Perf: collecting...",
    perf_history: []const u8 = "Perf history: unavailable",
    perf_command_stats: []const u8 = "Cmd/frame: collecting...",
    perf_panel_stats: []const u8 = "Panel draw: collecting...",
    benchmark_status: []const u8 = "Benchmark capture: idle",
    perf_benchmark_label: []const u8 = "",
    perf_charts: []const DebugSparklineSeriesView = &.{},
    node_watch_status: []const u8 = "Node service events: paused",
    scope_preview: []const u8 = "Node watch scope: role/project unavailable",
    show_user_scope_notice: bool = false,
    node_watch_filter: []const u8 = "",
    node_watch_replay_limit: []const u8 = "",
    debug_search_filter: []const u8 = "",
    filter_status: []const u8 = "Showing 0/0 events",
    jump_to_node_label: ?[]const u8 = null,
    diff_base_label: ?[]const u8 = null,
    latest_reload_diag: ?[]const u8 = null,
    selected_diag: ?[]const u8 = null,
    diff_preview: ?[]const u8 = null,
    show_large_payload_notice: bool = false,
};

pub const DebugSparklineSeriesView = struct {
    label: []const u8,
    points: []const f32 = &.{},
};

pub const DebugEventStreamView = struct {
    filtered_indices: []const u32 = &.{},
    selected_index: ?usize = null,
};

pub const DebugPanelAction = union(enum) {
    toggle_stream,
    refresh_snapshot,
    copy_perf,
    export_perf,
    clear_perf,
    toggle_benchmark,
    copy_benchmark,
    export_benchmark,
    clear_benchmark,
    refresh_node_feed,
    pause_node_feed,
    clear_search,
    jump_to_selected_node_fs,
    set_diff_base,
    clear_diff_base,
    generate_diff,
    copy_diff,
    export_diff,
    copy_selected_event,
};

pub const ConnectRole = enum {
    admin,
    user,
};

pub const SettingsConnectionState = enum {
    disconnected,
    connecting,
    connected,
    error_state,
};

pub const SettingsTerminalBackend = enum {
    plain_text,
    ghostty_vt,
};

pub const SettingsThemeMode = enum {
    pack_default,
    light,
    dark,
};

pub const SettingsThemeProfile = enum {
    auto,
    desktop,
    phone,
    tablet,
    fullscreen,
};

pub const ThemePackStatusKind = enum {
    idle,
    fetching,
    ok,
    failed,
};

pub const ThemePackQuickPickView = struct {
    label: []const u8,
    value: []const u8,
    selected: bool = false,
};

pub const LauncherSettingsModel = struct {
    connection_state: SettingsConnectionState = .disconnected,
    active_role: ConnectRole = .admin,
    watch_theme_pack: bool = false,
    auto_connect_on_launch: bool = false,
    ws_verbose_logs: bool = false,
    terminal_backend: SettingsTerminalBackend = .plain_text,
    theme_mode: SettingsThemeMode = .pack_default,
    theme_mode_locked: bool = false,
    theme_profile: SettingsThemeProfile = .auto,
    theme_pack_status_kind: ThemePackStatusKind = .idle,
    theme_pack_status_text: []const u8 = "",
    theme_pack_meta_text: ?[]const u8 = null,
    theme_pack_watch_supported: bool = true,
    theme_pack_reload_supported: bool = true,
    theme_pack_browse_supported: bool = false,
    theme_pack_refresh_supported: bool = true,
    theme_pack_quick_picks: []const ThemePackQuickPickView = &.{},
    theme_pack_recent: []const ThemePackQuickPickView = &.{},
    theme_pack_available: []const ThemePackQuickPickView = &.{},

    pub fn isConnecting(self: LauncherSettingsModel) bool {
        return self.connection_state == .connecting;
    }

    pub fn canRunConnectedActions(self: LauncherSettingsModel) bool {
        return self.connection_state == .connected;
    }
};

pub const LauncherSettingsAction = union(enum) {
    set_connect_role: ConnectRole,
    set_theme_mode: SettingsThemeMode,
    set_theme_profile: SettingsThemeProfile,
    toggle_watch_theme_pack,
    apply_theme_pack_input,
    select_theme_pack: []const u8,
    reload_theme_pack,
    disable_theme_pack,
    browse_theme_pack,
    refresh_theme_pack_list,
    toggle_auto_connect_on_launch,
    toggle_ws_verbose_logs,
    set_terminal_backend: SettingsTerminalBackend,
    connect,
    save_config,
    load_history,
    restore_last,
};

pub const WorkspaceMountEntryView = struct {
    index: usize = 0,
    mount_path: []const u8 = "",
    node_id: []const u8 = "",
    node_name: ?[]const u8 = null,
    export_name: []const u8 = "",
    selected: bool = false,
};

pub const WorkspaceBindEntryView = struct {
    index: usize = 0,
    bind_path: []const u8 = "",
    target_path: []const u8 = "",
    selected: bool = false,
};

pub const WorkspaceNodePickerEntryView = struct {
    index: usize = 0,
    node_id: []const u8 = "",
    node_name: []const u8 = "",
    online: bool = false,
    selected: bool = false,
};

pub const WorkspacePanelModel = struct {
    connected: bool = false,
    has_workspaces: bool = false,
    has_nodes: bool = false,
    can_create_workspace: bool = false,
    can_activate_workspace: bool = false,
    can_attach_session: bool = false,
    can_lock_workspace: bool = false,
    can_unlock_workspace: bool = false,
    can_remove_mount: bool = false,
    can_remove_bind: bool = false,
    can_rotate_token: bool = false,
    has_local_node: bool = false,

    pub fn controlsDisabled(self: WorkspacePanelModel) bool {
        return !self.connected;
    }
};

pub const WorkspaceListEntryView = struct {
    index: usize = 0,
    line: []const u8,
    selected: bool = false,
};

pub const WorkspaceNodeEntryView = struct {
    line: []const u8,
    degraded: bool = false,
};

pub const WorkspacePanelView = struct {
    title: []const u8 = "Workspace Overview",
    selected_workspace_button_label: []const u8 = "Select workspace",
    lock_state_text: []const u8 = "Workspace lock state: unknown",
    workspace_token: []const u8 = "",
    create_name: []const u8 = "",
    create_vision: []const u8 = "",
    template_id: []const u8 = "",
    operator_token: []const u8 = "",
    mount_path: []const u8 = "/",
    mount_node_id: []const u8 = "",
    mount_export_name: []const u8 = "",
    bind_path: []const u8 = "/repo",
    bind_target_path: []const u8 = "/nodes/local/fs",
    mount_hint: ?[]const u8 = null,
    workspace_error_text: ?[]const u8 = null,
    session_status_line: ?[]const u8 = null,
    session_status_warning: bool = false,
    selected_workspace_line: ?[]const u8 = null,
    setup_status_line: ?[]const u8 = null,
    setup_status_warning: bool = false,
    setup_vision_line: ?[]const u8 = null,
    template_line: ?[]const u8 = null,
    binds_line: ?[]const u8 = null,
    workspace_summary_line: ?[]const u8 = null,
    workspace_health_line: ?[]const u8 = null,
    workspace_health_warning: bool = false,
    workspace_health_error: bool = false,
    counts_line: ?[]const u8 = null,
    help_line: []const u8 = "Open Filesystem and Debug panels from the Windows menu.",
    workspaces: []const WorkspaceListEntryView = &.{},
    nodes: []const WorkspaceNodeEntryView = &.{},
    mounts: []const WorkspaceMountEntryView = &.{},
    binds: []const WorkspaceBindEntryView = &.{},
    nodes_for_picker: []const WorkspaceNodePickerEntryView = &.{},
    token_display: ?[]const u8 = null,
    local_node_id: ?[]const u8 = null,
    local_node_name: ?[]const u8 = null,
    local_node_ttl_text: ?[]const u8 = null,
    local_node_bootstrapped: bool = false,
    workspace_op_busy: bool = false,
    workspace_op_error: ?[]const u8 = null,
};

pub const WorkspacePanelAction = union(enum) {
    select_workspace_index: usize,
    create_workspace,
    refresh_workspace,
    activate_workspace,
    attach_session,
    lock_workspace,
    unlock_workspace,
    add_mount,
    remove_mount,
    add_bind,
    remove_bind,
    auth_status,
    rotate_auth_user,
    rotate_auth_admin,
    reveal_auth_admin,
    copy_auth_admin,
    reveal_auth_user,
    copy_auth_user,
    select_mount_index: usize,
    remove_selected_mount,
    select_bind_index: usize,
    remove_selected_bind,
    select_node_for_mount: usize,
    rotate_workspace_token,
    open_node_browser,
    rebootstrap_local_node,
};

pub const TerminalPanelModel = struct {
    connected: bool = false,
    has_session: bool = false,
    auto_poll: bool = false,
    has_input: bool = false,
    has_output: bool = false,

    pub fn controlsDisabled(self: TerminalPanelModel) bool {
        return !self.connected;
    }
};

pub const TerminalPanelView = struct {
    title: []const u8 = "Terminal",
    backend_line: []const u8 = "Backend: unknown",
    backend_detail: ?[]const u8 = null,
    session_line: []const u8 = "Session: (unknown)",
    status_text: ?[]const u8 = null,
    error_text: ?[]const u8 = null,
    input_text: []const u8 = "",
    start_label: []const u8 = "Start",
};

pub const TerminalOutputView = struct {
    total_lines: usize = 0,
    line_height: f32 = 14.0,
    empty_text: []const u8 = "(terminal output empty)",
};

pub const TerminalPanelAction = union(enum) {
    start_or_restart,
    stop,
    read,
    resize_default,
    clear_output,
    toggle_auto_poll,
    send_ctrl_c,
    send_input,
    copy_output,
};

test "AttachmentOpen deinit frees optional buffers" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var attachment = AttachmentOpen{
        .name = try allocator.dupe(u8, "file.txt"),
        .kind = try allocator.dupe(u8, "text/plain"),
        .url = try allocator.dupe(u8, "file:///tmp/file.txt"),
        .role = try allocator.dupe(u8, "assistant"),
        .timestamp = 1234,
        .body = try allocator.dupe(u8, "hello"),
        .status = try allocator.dupe(u8, "ok"),
        .truncated = false,
    };

    attachment.deinit(allocator);
}

test "DebugPanelModel helper gates match expected connection state" {
    const disconnected = DebugPanelModel{};
    try std.testing.expect(!disconnected.canRefreshSnapshot());
    try std.testing.expect(!disconnected.canRefreshNodeFeed());
    try std.testing.expect(!disconnected.canPauseNodeFeed());

    const connected = DebugPanelModel{
        .connected = true,
        .stream_enabled = true,
        .node_watch_enabled = true,
    };
    try std.testing.expect(connected.canRefreshSnapshot());
    try std.testing.expect(connected.canRefreshNodeFeed());
    try std.testing.expect(connected.canPauseNodeFeed());
}

test "LauncherSettingsModel helper gates match connection state" {
    const connecting = LauncherSettingsModel{ .connection_state = .connecting };
    try std.testing.expect(connecting.isConnecting());
    try std.testing.expect(!connecting.canRunConnectedActions());

    const connected = LauncherSettingsModel{ .connection_state = .connected };
    try std.testing.expect(!connected.isConnecting());
    try std.testing.expect(connected.canRunConnectedActions());
}

test "WorkspacePanelModel helper gates match connection state" {
    const disconnected = WorkspacePanelModel{};
    try std.testing.expect(disconnected.controlsDisabled());

    const connected = WorkspacePanelModel{ .connected = true };
    try std.testing.expect(!connected.controlsDisabled());
}

test "FilesystemPanelModel helper gates reflect explorer state" {
    const idle = FilesystemPanelModel{
        .connected = true,
        .has_selected_entry = true,
    };
    try std.testing.expect(!idle.controlsDisabled());
    try std.testing.expect(idle.canOpenSelectedEntry());
    try std.testing.expect(!idle.hasActiveFilters());

    const filtered = FilesystemPanelModel{
        .connected = true,
        .hide_hidden = true,
        .hide_runtime_noise = true,
    };
    try std.testing.expect(filtered.hasActiveFilters());

    const busy = FilesystemPanelModel{
        .connected = true,
        .busy = true,
        .has_selected_entry = true,
    };
    try std.testing.expect(busy.controlsDisabled());
    try std.testing.expect(!busy.canOpenSelectedEntry());
}

test "FilesystemToolsPanelModel helper gates reflect service state" {
    const idle = FilesystemToolsPanelModel{
        .connected = true,
        .contract_service_count = 2,
    };
    try std.testing.expect(!idle.controlsDisabled());
    try std.testing.expect(idle.hasContractPager());

    const disconnected = FilesystemToolsPanelModel{};
    try std.testing.expect(disconnected.controlsDisabled());
    try std.testing.expect(!disconnected.hasContractPager());
}
