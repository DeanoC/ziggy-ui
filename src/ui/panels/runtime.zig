const std = @import("std");
const state = @import("../../client/state.zig");
const config = @import("../../client/config.zig");
const agent_registry = @import("../../client/agent_registry.zig");
const session_keys = @import("../../client/session_keys.zig");
const workspace = @import("../workspace.zig");
const panel_manager = @import("../panel_manager.zig");
const draw_context = @import("../draw_context.zig");
const theme = @import("../theme.zig");
const ui_command_inbox = @import("../ui_command_inbox.zig");
const theme_runtime = @import("../theme_engine/runtime.zig");
const profiler = @import("../../utils/profiler.zig");
const interfaces = @import("interfaces.zig");
const panels = @import("panels.zig");
const operator_view = panels.operator;
const approvals_inbox_view = panels.approvals_inbox;

const chat_panel = panels.chat;
const code_editor_panel = panels.code_editor;
const tool_output_panel = panels.tool_output;
const control_panel = panels.control;
const connection_panel = panels.connection;
const agents_panel = panels.agents;
const inbox_panel = panels.inbox;
const workboard_panel = panels.workboard;
const settings_panel = panels.settings;
const showcase_panel = panels.showcase;

pub const AttachmentOpen = interfaces.AttachmentOpen;
pub const UiAction = interfaces.UiAction;
pub const DrawResult = interfaces.DrawResult;

pub fn drawContents(
    allocator: std.mem.Allocator,
    ctx: *state.ClientContext,
    cfg: *config.Config,
    registry: *agent_registry.AgentRegistry,
    is_connected: bool,
    app_version: []const u8,
    panel: *workspace.Panel,
    panel_rect: ?draw_context.Rect,
    inbox: *ui_command_inbox.UiCommandInbox,
    manager: *panel_manager.PanelManager,
    action: *UiAction,
    pending_attachment: *?AttachmentOpen,
    theme_pack_override: ?[]const u8,
    install_profile_only_mode: bool,
) DrawResult {
    var result: DrawResult = .{};
    const zone = profiler.zone(@src(), "ui.panel");
    defer zone.end();

    switch (panel.kind) {
        .Chat => {
            var agent_id = panel.data.Chat.agent_id;
            if (agent_id == null) {
                if (panel.data.Chat.session_key) |session_key| {
                    if (session_keys.parse(session_key)) |parts| {
                        panel.data.Chat.agent_id = allocator.dupe(u8, parts.agent_id) catch panel.data.Chat.agent_id;
                        agent_id = panel.data.Chat.agent_id;
                        manager.workspace.markDirty();
                    }
                }
            }

            var resolved_session_key = panel.data.Chat.session_key;
            if (resolved_session_key == null and agent_id != null) {
                if (registry.find(agent_id.?)) |agent| {
                    if (agent.default_session_key) |default_key| {
                        resolved_session_key = default_key;
                    }
                }
            }
            if (resolved_session_key == null) {
                if (ctx.current_session) |current| {
                    resolved_session_key = current;
                    if (panel.data.Chat.session_key == null) {
                        panel.data.Chat.session_key = allocator.dupe(u8, current) catch panel.data.Chat.session_key;
                        manager.workspace.markDirty();
                    }
                    if (agent_id == null) {
                        if (session_keys.parse(current)) |parts| {
                            panel.data.Chat.agent_id = allocator.dupe(u8, parts.agent_id) catch panel.data.Chat.agent_id;
                            agent_id = panel.data.Chat.agent_id;
                            manager.workspace.markDirty();
                        }
                    }
                }
            }

            const agent_info = resolveAgentInfo(registry, agent_id);
            if (!std.mem.eql(u8, panel.title, agent_info.name)) {
                if (allocator.dupe(u8, agent_info.name)) |new_title| {
                    allocator.free(panel.title);
                    panel.title = new_title;
                    manager.workspace.markDirty();
                } else |_| {}
            }

            const session_state = if (resolved_session_key) |session_key|
                ctx.getOrCreateSessionState(session_key) catch null
            else
                null;

            const chat_action = chat_panel.draw(
                allocator,
                &panel.data.Chat,
                agent_id orelse "main",
                resolved_session_key,
                session_state,
                agent_info.icon,
                agent_info.name,
                ctx.sessions.items,
                inbox,
                ctx.approvals.items.len,
                panel_rect,
            );
            if (chat_action.send_message) |message| {
                if (resolved_session_key) |session_key| {
                    const key_copy = allocator.dupe(u8, session_key) catch null;
                    if (key_copy) |owned| {
                        action.send_message = .{ .session_key = owned, .message = message };
                    } else {
                        allocator.free(message);
                    }
                } else {
                    allocator.free(message);
                }
            }
            replaceOwnedSlice(allocator, &action.select_session, chat_action.select_session);
            setOwnedSlice(allocator, &action.select_session_id, chat_action.select_session_id);
            replaceOwnedSlice(allocator, &action.new_chat_session_key, chat_action.new_chat_session_key);

            if (chat_action.open_activity_panel) {
                manager.ensurePanel(.Inbox);
            }
            if (chat_action.open_approvals_panel) {
                manager.ensurePanel(.ApprovalsInbox);
            }

            result.session_key = resolved_session_key;
            result.agent_id = agent_id;
        },
        .CodeEditor => {
            if (code_editor_panel.draw(panel, allocator, panel_rect)) {
                manager.workspace.markDirty();
            }
        },
        .ToolOutput => {
            tool_output_panel.draw(panel, allocator, panel_rect);
        },
        .ProjectWorkspace => {
            drawHostInterceptPanelPlaceholder(allocator, panel, panel_rect, "Project workspace view is provided by the host app.");
        },
        .FilesystemBrowser => {
            drawHostInterceptPanelPlaceholder(allocator, panel, panel_rect, "Filesystem browser view is provided by the host app.");
        },
        .DebugStream => {
            drawHostInterceptPanelPlaceholder(allocator, panel, panel_rect, "Debug stream view is provided by the host app.");
        },
        .Control => {
            const control_action = control_panel.draw(
                allocator,
                ctx,
                cfg,
                registry,
                is_connected,
                app_version,
                &panel.data.Control,
                panel_rect,
                theme_pack_override,
                install_profile_only_mode,
            );
            action.refresh_sessions = action.refresh_sessions or control_action.refresh_sessions;
            action.new_session = action.new_session or control_action.new_session;
            action.connect = action.connect or control_action.connect;
            action.disconnect = action.disconnect or control_action.disconnect;
            action.save_config = action.save_config or control_action.save_config;
            action.reload_theme_pack = action.reload_theme_pack or control_action.reload_theme_pack;
            action.browse_theme_pack = action.browse_theme_pack or control_action.browse_theme_pack;
            action.browse_theme_pack_override = action.browse_theme_pack_override or control_action.browse_theme_pack_override;
            action.clear_theme_pack_override = action.clear_theme_pack_override or control_action.clear_theme_pack_override;
            action.reload_theme_pack_override = action.reload_theme_pack_override or control_action.reload_theme_pack_override;
            action.clear_saved = action.clear_saved or control_action.clear_saved;
            action.config_updated = action.config_updated or control_action.config_updated;
            action.check_updates = action.check_updates or control_action.check_updates;
            action.open_release = action.open_release or control_action.open_release;
            action.download_update = action.download_update or control_action.download_update;
            action.open_download = action.open_download or control_action.open_download;
            action.install_update = action.install_update or control_action.install_update;

            action.node_profile_apply_client = action.node_profile_apply_client or control_action.node_profile_apply_client;
            action.node_profile_apply_service = action.node_profile_apply_service or control_action.node_profile_apply_service;
            action.node_profile_apply_session = action.node_profile_apply_session or control_action.node_profile_apply_session;
            action.node_service_install_onlogon = action.node_service_install_onlogon or control_action.node_service_install_onlogon;
            action.node_service_start = action.node_service_start or control_action.node_service_start;
            action.node_service_stop = action.node_service_stop or control_action.node_service_stop;
            action.node_service_status = action.node_service_status or control_action.node_service_status;
            action.node_service_uninstall = action.node_service_uninstall or control_action.node_service_uninstall;
            action.open_node_logs = action.open_node_logs or control_action.open_node_logs;
            action.refresh_nodes = action.refresh_nodes or control_action.refresh_nodes;
            action.clear_node_result = action.clear_node_result or control_action.clear_node_result;
            action.clear_operator_notice = action.clear_operator_notice or control_action.clear_operator_notice;

            if (control_action.new_chat_agent_id) |agent_id| {
                replaceOwnedSlice(allocator, &action.new_chat_agent_id, agent_id);
            }
            if (control_action.open_session) |open_session| {
                action.open_session = open_session;
            }
            if (control_action.set_default_session) |set_default| {
                action.set_default_session = set_default;
            }
            replaceOwnedSlice(allocator, &action.delete_session, control_action.delete_session);
            if (control_action.add_agent) |add_agent| {
                action.add_agent = add_agent;
            }
            replaceOwnedSlice(allocator, &action.remove_agent_id, control_action.remove_agent_id);
            replaceOwnedSlice(allocator, &action.select_node, control_action.select_node);
            if (control_action.invoke_node) |invoke| {
                action.invoke_node = invoke;
            }
            replaceOwnedSlice(allocator, &action.describe_node, control_action.describe_node);
            if (control_action.resolve_approval) |resolve| {
                action.resolve_approval = resolve;
            }
            replaceOwnedSlice(allocator, &action.clear_node_describe, control_action.clear_node_describe);
            if (control_action.open_attachment) |attachment| {
                pending_attachment.* = attachment;
            }
            replaceOwnedSlice(allocator, &action.select_session, control_action.select_session);
            if (control_action.select_session != null) {
                setOwnedSlice(allocator, &action.select_session_id, null);
            }
            replaceOwnedSlice(allocator, &action.open_url, control_action.open_url);
        },
        .Agents => {
            const agents_action = agents_panel.draw(
                allocator,
                ctx,
                registry,
                &panel.data.Agents,
                panel_rect,
            );
            action.refresh_sessions = action.refresh_sessions or agents_action.refresh;
            if (agents_action.new_chat_agent_id) |agent_id| {
                replaceOwnedSlice(allocator, &action.new_chat_agent_id, agent_id);
            }
            if (agents_action.open_session) |open_session| {
                action.open_session = open_session;
            }
            if (agents_action.set_default) |set_default| {
                action.set_default_session = set_default;
            }
            if (agents_action.delete_session) |session_key| {
                replaceOwnedSlice(allocator, &action.delete_session, session_key);
            }
            if (agents_action.add_agent) |add_agent| {
                action.add_agent = add_agent;
            }
            if (agents_action.remove_agent_id) |agent_id| {
                replaceOwnedSlice(allocator, &action.remove_agent_id, agent_id);
            }
            replaceAgentFileAction(allocator, &action.open_agent_file, agents_action.open_agent_file);
        },
        .Operator => {
            const op_action = operator_view.draw(allocator, ctx, is_connected, panel_rect);
            action.refresh_nodes = action.refresh_nodes or op_action.refresh_nodes;
            replaceOwnedSlice(allocator, &action.select_node, op_action.select_node);
            if (op_action.invoke_node) |invoke| {
                action.invoke_node = invoke;
            }
            replaceOwnedSlice(allocator, &action.describe_node, op_action.describe_node);
            if (op_action.resolve_approval) |resolve| {
                action.resolve_approval = resolve;
            }
            replaceOwnedSlice(allocator, &action.clear_node_describe, op_action.clear_node_describe);
            action.clear_node_result = action.clear_node_result or op_action.clear_node_result;
            action.clear_operator_notice = action.clear_operator_notice or op_action.clear_operator_notice;
        },
        .ApprovalsInbox => {
            const approvals_action = approvals_inbox_view.draw(allocator, ctx, panel_rect);
            if (approvals_action.resolve_approval) |resolve| {
                action.resolve_approval = resolve;
            }
        },
        .Inbox => {
            if (panel_rect) |content_rect| {
                const inbox_action = inbox_panel.draw(allocator, ctx, &panel.data.Inbox, content_rect);
                if (inbox_action.open_approvals_panel) {
                    manager.ensurePanel(.ApprovalsInbox);
                }
            }
        },
        .Workboard => {
            const wb_action = workboard_panel.draw(ctx, is_connected, panel_rect);
            action.refresh_workboard = action.refresh_workboard or wb_action.refresh;
        },
        .Connection => {
            const connection_action = connection_panel.draw(
                allocator,
                cfg,
                ctx.state,
                is_connected,
                &ctx.update_state,
                app_version,
                panel_rect,
                theme_pack_override,
                install_profile_only_mode,
            );
            mergeSettingsPanelAction(action, connection_action);
        },
        .Settings => {
            const settings_action = settings_panel.draw(
                allocator,
                cfg,
                ctx.state,
                is_connected,
                &ctx.update_state,
                app_version,
                panel_rect,
                theme_pack_override,
                install_profile_only_mode,
            );
            mergeSettingsPanelAction(action, settings_action);
        },
        .Showcase => {
            const showcase_action = showcase_panel.draw(allocator, panel_rect, .{
                .expressive_enabled = cfg.ui_expressive_enabled,
                .enable_3d = cfg.ui_expressive_enabled and cfg.ui_3d_enabled,
            });
            if (showcase_action.reload_effective_pack) {
                if (theme_pack_override != null) {
                    action.reload_theme_pack_override = true;
                } else {
                    action.reload_theme_pack = true;
                }
            }
            if (showcase_action.open_pack_root) {
                const root = theme_runtime.getThemePackRootPath() orelse "themes";
                const owned = allocator.dupe(u8, root) catch null;
                replaceOwnedSlice(allocator, &action.open_url, owned);
            }
        },
    }

    return result;
}

fn drawHostInterceptPanelPlaceholder(
    allocator: std.mem.Allocator,
    panel: *workspace.Panel,
    panel_rect: ?draw_context.Rect,
    subtitle: []const u8,
) void {
    const rect = panel_rect orelse return;
    const t = theme.activeTheme();
    var dc = draw_context.DrawContext.init(allocator, .{ .direct = .{} }, t, rect);
    defer dc.deinit();

    dc.drawRect(rect, .{ .fill = t.colors.surface, .stroke = t.colors.border, .thickness = 1.0 });

    const left = rect.min[0] + t.spacing.md;
    var y = rect.min[1] + t.spacing.md;
    dc.drawText(panel.title, .{ left, y }, .{ .color = t.colors.text_primary });
    y += dc.lineHeight() + t.spacing.xs;
    dc.drawText(subtitle, .{ left, y }, .{ .color = t.colors.text_secondary });
    y += dc.lineHeight() + t.spacing.xs;
    dc.drawText("Open this panel from your host UI integration.", .{ left, y }, .{ .color = t.colors.text_secondary });
}

pub fn deinit(allocator: std.mem.Allocator) void {
    panels.deinit(allocator);
    operator_view.deinit(allocator);
}

fn replaceOwnedSlice(allocator: std.mem.Allocator, target: *?[]u8, value: ?[]u8) void {
    if (value == null) return;
    if (target.*) |existing| {
        allocator.free(existing);
    }
    target.* = value;
}

fn setOwnedSlice(allocator: std.mem.Allocator, target: *?[]u8, value: ?[]u8) void {
    if (target.*) |existing| {
        allocator.free(existing);
    }
    target.* = value;
}

fn replaceAgentFileAction(
    allocator: std.mem.Allocator,
    target: *?agents_panel.AgentFileOpenAction,
    value: ?agents_panel.AgentFileOpenAction,
) void {
    if (value == null) return;
    if (target.*) |*existing| {
        existing.deinit(allocator);
    }
    target.* = value;
}

const AgentInfo = struct {
    name: []const u8,
    icon: []const u8,
};

fn resolveAgentInfo(registry: *agent_registry.AgentRegistry, agent_id: ?[]const u8) AgentInfo {
    if (agent_id) |id| {
        if (registry.find(id)) |agent| {
            return .{ .name = agent.display_name, .icon = agent.icon };
        }
        return .{ .name = id, .icon = "?" };
    }
    return .{ .name = "Agent", .icon = "?" };
}

fn mergeSettingsPanelAction(action: *UiAction, settings_action: anytype) void {
    action.connect = action.connect or settings_action.connect;
    action.disconnect = action.disconnect or settings_action.disconnect;
    action.save_config = action.save_config or settings_action.save;
    action.reload_theme_pack = action.reload_theme_pack or settings_action.reload_theme_pack;
    action.browse_theme_pack = action.browse_theme_pack or settings_action.browse_theme_pack;
    action.browse_theme_pack_override = action.browse_theme_pack_override or settings_action.browse_theme_pack_override;
    action.clear_theme_pack_override = action.clear_theme_pack_override or settings_action.clear_theme_pack_override;
    action.reload_theme_pack_override = action.reload_theme_pack_override or settings_action.reload_theme_pack_override;
    action.clear_saved = action.clear_saved or settings_action.clear_saved;
    action.config_updated = action.config_updated or settings_action.config_updated;
    action.check_updates = action.check_updates or settings_action.check_updates;
    action.open_release = action.open_release or settings_action.open_release;
    action.download_update = action.download_update or settings_action.download_update;
    action.open_download = action.open_download or settings_action.open_download;
    action.install_update = action.install_update or settings_action.install_update;
    action.node_profile_apply_client = action.node_profile_apply_client or settings_action.node_profile_apply_client;
    action.node_profile_apply_service = action.node_profile_apply_service or settings_action.node_profile_apply_service;
    action.node_profile_apply_session = action.node_profile_apply_session or settings_action.node_profile_apply_session;
    action.node_service_install_onlogon = action.node_service_install_onlogon or settings_action.node_service_install_onlogon;
    action.node_service_start = action.node_service_start or settings_action.node_service_start;
    action.node_service_stop = action.node_service_stop or settings_action.node_service_stop;
    action.node_service_status = action.node_service_status or settings_action.node_service_status;
    action.node_service_uninstall = action.node_service_uninstall or settings_action.node_service_uninstall;
    action.open_node_logs = action.open_node_logs or settings_action.open_node_logs;
}
