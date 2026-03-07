const workspace = @import("../workspace.zig");
const dock_graph = @import("../layout/dock_graph.zig");
const operator_view = @import("../operator_view.zig");
const agents_panel = @import("agents_panel.zig");
const std = @import("std");

pub const AttachmentOpen = struct {
    name: []u8,
    kind: []u8,
    url: []u8,
    body: ?[]u8 = null,
    status: ?[]u8 = null,
    truncated: bool = false,

    pub fn deinit(self: *AttachmentOpen, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.kind);
        allocator.free(self.url);
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

pub const FilesystemPanelModel = struct {
    connected: bool = false,
    busy: bool = false,
    has_service_runtime_root: bool = false,
    has_selected_contract_service: bool = false,
    contract_service_count: usize = 0,

    pub fn controlsDisabled(self: FilesystemPanelModel) bool {
        return !self.connected or self.busy;
    }

    pub fn hasContractPager(self: FilesystemPanelModel) bool {
        return self.contract_service_count > 1;
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
    open_entry_index: usize,
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

pub const FilesystemEntryView = struct {
    index: usize = 0,
    label: []const u8,
    badge: ?[]const u8 = null,
};

pub const FilesystemPanelView = struct {
    path_label: []const u8 = "/",
    error_text: ?[]const u8 = null,
    selected_contract_label: []const u8 = "Selected: (none loaded)",
    contract_payload: []const u8 = "",
    entries: []const FilesystemEntryView = &.{},
    preview_title: []const u8 = "(select a file to preview)",
    preview_text: ?[]const u8 = null,
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

pub const LauncherSettingsModel = struct {
    connection_state: SettingsConnectionState = .disconnected,
    active_role: ConnectRole = .admin,
    watch_theme_pack: bool = false,
    auto_connect_on_launch: bool = false,
    ws_verbose_logs: bool = false,
    terminal_backend: SettingsTerminalBackend = .plain_text,

    pub fn isConnecting(self: LauncherSettingsModel) bool {
        return self.connection_state == .connecting;
    }

    pub fn canRunConnectedActions(self: LauncherSettingsModel) bool {
        return self.connection_state == .connected;
    }
};

pub const LauncherSettingsAction = union(enum) {
    set_connect_role: ConnectRole,
    toggle_watch_theme_pack,
    toggle_auto_connect_on_launch,
    toggle_ws_verbose_logs,
    set_terminal_backend: SettingsTerminalBackend,
    connect,
    save_config,
    load_history,
    restore_last,
};

pub const ProjectPanelModel = struct {
    connected: bool = false,
    has_projects: bool = false,
    has_nodes: bool = false,
    can_create_project: bool = false,
    can_activate_project: bool = false,
    can_lock_project: bool = false,
    can_unlock_project: bool = false,

    pub fn controlsDisabled(self: ProjectPanelModel) bool {
        return !self.connected;
    }
};

pub const ProjectListEntryView = struct {
    index: usize = 0,
    line: []const u8,
    selected: bool = false,
};

pub const ProjectNodeEntryView = struct {
    line: []const u8,
    degraded: bool = false,
};

pub const ProjectPanelView = struct {
    title: []const u8 = "Project Workspace",
    selected_project_button_label: []const u8 = "Select project",
    lock_state_text: []const u8 = "Project lock state: unknown",
    project_token: []const u8 = "",
    create_name: []const u8 = "",
    create_vision: []const u8 = "",
    operator_token: []const u8 = "",
    mount_path: []const u8 = "/",
    mount_node_id: []const u8 = "",
    mount_export_name: []const u8 = "",
    mount_hint: ?[]const u8 = null,
    workspace_error_text: ?[]const u8 = null,
    selected_project_line: ?[]const u8 = null,
    setup_status_line: ?[]const u8 = null,
    setup_status_warning: bool = false,
    setup_vision_line: ?[]const u8 = null,
    workspace_summary_line: ?[]const u8 = null,
    workspace_health_line: ?[]const u8 = null,
    workspace_health_warning: bool = false,
    workspace_health_error: bool = false,
    counts_line: ?[]const u8 = null,
    help_line: []const u8 = "Open Filesystem and Debug panels from the Windows menu.",
    projects: []const ProjectListEntryView = &.{},
    nodes: []const ProjectNodeEntryView = &.{},
};

pub const ProjectPanelAction = union(enum) {
    select_project_index: usize,
    create_project,
    refresh_workspace,
    activate_project,
    lock_project,
    unlock_project,
    add_mount,
    remove_mount,
    auth_status,
    rotate_auth_user,
    rotate_auth_admin,
    reveal_auth_admin,
    copy_auth_admin,
    reveal_auth_user,
    copy_auth_user,
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

test "ProjectPanelModel helper gates match connection state" {
    const disconnected = ProjectPanelModel{};
    try std.testing.expect(disconnected.controlsDisabled());

    const connected = ProjectPanelModel{ .connected = true };
    try std.testing.expect(!connected.controlsDisabled());
}
