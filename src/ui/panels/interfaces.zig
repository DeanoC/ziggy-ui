const workspace = @import("../workspace.zig");
const dock_graph = @import("../layout/dock_graph.zig");
const operator_view = @import("../operator_view.zig");
const agents_panel = @import("agents_panel.zig");
const panel_contract = @import("ziggy-ui-panels");

pub const AttachmentOpen = panel_contract.AttachmentOpen;

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

pub const DrawResult = panel_contract.DrawResult;
