const std = @import("std");
const chat_view = @import("../chat_view.zig");
const input_panel = @import("../input_panel.zig");
const ui_command_inbox = @import("../ui_command_inbox.zig");
const theme = @import("../theme.zig");
const colors = @import("../theme/colors.zig");
const draw_context = @import("../draw_context.zig");
const input_router = @import("../input/input_router.zig");
const input_state = @import("../input/input_state.zig");
const cursor = @import("../input/cursor.zig");
const widgets = @import("../widgets/widgets.zig");
const workspace = @import("../workspace.zig");
const surface_chrome = @import("../surface_chrome.zig");
const session_presenter = @import("../session_presenter.zig");
const debug_visibility = @import("../debug_visibility.zig");

pub const ChatPanelAction = struct {
    send_message: ?[]u8 = null,
    select_session: ?[]u8 = null,
    select_session_id: ?[]u8 = null,
    new_chat_session_key: ?[]u8 = null,

    open_activity_panel: bool = false,
    open_approvals_panel: bool = false,
};

const HeaderAction = struct {
    picker_rect: ?draw_context.Rect = null,
    request_new_chat: bool = false,
    open_activity_panel: bool = false,
    open_approvals_panel: bool = false,
};

const SessionSelection = struct {
    key: ?[]u8 = null,
    session_id: ?[]u8 = null,
};

const CopyContextMenuAction = enum {
    none,
    copy_selection,
    copy_all,
};

/// Generic Chat Panel that works with any Message and Session types
pub fn ChatPanel(comptime Message: type, comptime Session: type) type {
    // Validate Message type has required fields
    comptime {
        const msg_info = @typeInfo(Message);
        if (msg_info != .@"struct") @compileError("Message must be a struct");
        
        const required_msg_fields = .{"id", "role", "content", "timestamp"};
        for (required_msg_fields) |field| {
            if (!@hasField(Message, field)) {
                @compileError("Message type missing required field: " ++ field);
            }
        }
        
        // Validate Session type
        const session_info = @typeInfo(Session);
        if (session_info != .@"struct") @compileError("Session must be a struct");
        
        const required_session_fields = .{"key"};
        for (required_session_fields) |field| {
            if (!@hasField(Session, field)) {
                @compileError("Session type missing required field: " ++ field);
            }
        }
    }

    return struct {
        pub const MessageType = Message;
        pub const SessionType = Session;

        fn countWarnErrorActivity(messages: []const Message, inbox: ?*const ui_command_inbox.UiCommandInbox) usize {
            _ = inbox;
            var count: usize = 0;
            var scanned: usize = 0;
            var idx: usize = messages.len;
            const max_scan: usize = 200;
            while (idx > 0 and scanned < max_scan) {
                idx -= 1;
                scanned += 1;
                const msg = messages[idx];
                if (!isToolRole(msg.role)) continue;
                if (looksWarnOrError(msg.content)) {
                    count += 1;
                }
            }
            return count;
        }

        pub fn draw(
            allocator: std.mem.Allocator,
            panel_state: *workspace.ChatPanel,
            agent_id: []const u8,
            session_key: ?[]const u8,
            messages: []const Message,
            stream_text: ?[]const u8,
            inbox: ?*const ui_command_inbox.UiCommandInbox,
            agent_icon: []const u8,
            agent_name: []const u8,
            sessions: []const Session,
            pending_approvals_count: usize,
            rect_override: ?draw_context.Rect,
            session_state: ?SessionState,
        ) ChatPanelAction {
            _ = session_state;
            var action = ChatPanelAction{};
            const t = theme.activeTheme();

            normalizeSelectedSessionId(allocator, panel_state, session_key, sessions);

            const status_text: []const u8 = "";
            const is_busy = false;
            const busy_phase: u8 = 0;
            
            const composer_status_buf: [80]u8 = undefined;
            _ = composer_status_buf;
            const composer_status_text: ?[]const u8 = null;

            const has_session = session_key != null;

            const debug_tier = debug_visibility.current_tier;
            const show_tool_output = debug_visibility.showToolOutput(debug_tier);
            const activity_warn_error_count = countWarnErrorActivity(messages, inbox);

            const ChatView = chat_view.ChatView(Message);
            const has_selection_select = ChatView.hasSelectCopySelection(&panel_state.view);
            const has_selection_custom = ChatView.hasSelection(&panel_state.view);
            const has_selection = if (panel_state.select_copy_mode) has_selection_select else has_selection_custom;
            
            const panel_rect = rect_override orelse return action;
            var panel_ctx = draw_context.DrawContext.init(allocator, .{ .direct = .{} }, t, panel_rect);
            defer panel_ctx.deinit();
            surface_chrome.drawBackground(&panel_ctx, panel_rect);

            const queue = input_router.getQueue();

            const header_width = panel_rect.size()[0];
            const row_height = panel_ctx.lineHeight();
            const control_height = @max(row_height, 20.0);
            const top_pad = t.spacing.xs;
            const bottom_pad = t.spacing.xs;
            const header_height = top_pad + control_height + bottom_pad;
            const header_rect = draw_context.Rect.fromMinSize(panel_rect.min, .{ header_width, header_height });
            
            const header_action = drawHeader(
                &panel_ctx,
                header_rect,
                queue,
                agent_id,
                agent_icon,
                agent_name,
                status_text,
                is_busy,
                busy_phase,
                sessions,
                session_key,
                panel_state.selected_session_id,
                has_session,
                &panel_state.select_copy_mode,
                debug_tier,
                activity_warn_error_count,
                pending_approvals_count,
                &panel_state.session_picker_open,
                control_height,
            );

            const separator_h: f32 = 1.0;
            const separator_gap = t.spacing.xs;
            const separator_block = separator_h + separator_gap * 2.0;

            var cursor_y = header_rect.max[1];
            const sep1_y = cursor_y + separator_gap;
            const sep1_rect = draw_context.Rect.fromMinSize(.{ panel_rect.min[0], sep1_y }, .{ panel_rect.size()[0], separator_h });
            panel_ctx.drawRect(sep1_rect, .{ .fill = t.colors.divider });
            const content_top_y = sep1_rect.max[1] + separator_gap;
            cursor_y = content_top_y;

            const remaining = @max(0.0, panel_rect.max[1] - content_top_y);
            const available_for_history_input = if (remaining > separator_block) remaining - separator_block else 0.0;
            const min_history_height: f32 = 96.0;
            const min_input_height: f32 = 92.0;

            var ratio = panel_state.composer_ratio;
            if (!(ratio > 0.05 and ratio < 0.95)) {
                ratio = 0.24;
            }

            var max_input_height = if (available_for_history_input > min_history_height)
                available_for_history_input - min_history_height
            else
                available_for_history_input;
            if (max_input_height < 0.0) max_input_height = 0.0;

            var input_height = available_for_history_input * ratio;
            const min_input_bound = @min(min_input_height, max_input_height);
            if (max_input_height > 0.0) {
                input_height = std.math.clamp(input_height, min_input_bound, max_input_height);
            } else {
                input_height = 0.0;
            }
            var history_height = @max(0.0, available_for_history_input - input_height);

            const splitter_hit_height: f32 = @max(10.0, t.spacing.sm * 2.0);
            var splitter_center_y = content_top_y + history_height + separator_gap;
            var splitter_rect = draw_context.Rect.fromMinSize(
                .{ panel_rect.min[0], splitter_center_y - splitter_hit_height * 0.5 },
                .{ panel_rect.size()[0], splitter_hit_height },
            );

            for (queue.events.items) |evt| {
                switch (evt) {
                    .mouse_down => |md| {
                        if (md.button == .left and splitter_rect.contains(md.pos)) {
                            panel_state.composer_split_dragging = true;
                        }
                    },
                    .mouse_up => |mu| {
                        if (mu.button == .left) {
                            panel_state.composer_split_dragging = false;
                        }
                    },
                    else => {},
                }
            }

            const splitter_hover = splitter_rect.contains(queue.state.mouse_pos);
            if (splitter_hover or panel_state.composer_split_dragging) {
                cursor.set(.resize_ns);
            }

            if (panel_state.composer_split_dragging and available_for_history_input > 0.0) {
                const min_history = @min(min_history_height, available_for_history_input);
                const max_history = @max(min_history, available_for_history_input - @min(min_input_height, available_for_history_input));
                history_height = std.math.clamp(queue.state.mouse_pos[1] - content_top_y, min_history, max_history);
                input_height = @max(0.0, available_for_history_input - history_height);
                panel_state.composer_ratio = if (available_for_history_input > 0.0) input_height / available_for_history_input else ratio;
                splitter_center_y = content_top_y + history_height + separator_gap;
                splitter_rect = draw_context.Rect.fromMinSize(
                    .{ panel_rect.min[0], splitter_center_y - splitter_hit_height * 0.5 },
                    .{ panel_rect.size()[0], splitter_hit_height },
                );
            } else {
                panel_state.composer_ratio = ratio;
            }

            const history_rect = draw_context.Rect.fromMinSize(.{ panel_rect.min[0], cursor_y }, .{ panel_rect.size()[0], history_height });
            
            if (panel_state.select_copy_mode) {
                ChatView.drawSelectCopy(
                    allocator,
                    &panel_ctx,
                    history_rect,
                    queue,
                    &panel_state.view,
                    session_key,
                    messages,
                    stream_text,
                    inbox,
                    .{
                        .select_copy_mode = panel_state.select_copy_mode,
                        .show_tool_output = show_tool_output,
                        .assistant_label = agent_name,
                        .debug_tier = debug_tier,
                    },
                );
            } else {
                ChatView.drawCustom(
                    allocator,
                    &panel_ctx,
                    history_rect,
                    queue,
                    &panel_state.view,
                    session_key,
                    messages,
                    stream_text,
                    inbox,
                    .{
                        .select_copy_mode = panel_state.select_copy_mode,
                        .show_tool_output = show_tool_output,
                        .assistant_label = agent_name,
                        .debug_tier = debug_tier,
                    },
                );
            }

            for (queue.events.items) |evt| {
                switch (evt) {
                    .mouse_up => |mu| {
                        if (mu.button != .right) continue;
                        if (history_rect.contains(mu.pos)) {
                            panel_state.copy_context_menu_open = true;
                            panel_state.copy_context_menu_anchor = mu.pos;
                        } else {
                            panel_state.copy_context_menu_open = false;
                        }
                    },
                    else => {},
                }
            }

            cursor_y = history_rect.max[1];
            const sep2_y = cursor_y + separator_gap;
            const sep2_rect = draw_context.Rect.fromMinSize(.{ panel_rect.min[0], sep2_y }, .{ panel_rect.size()[0], separator_h });
            const divider_color = if (splitter_hover or panel_state.composer_split_dragging)
                colors.withAlpha(t.colors.primary, 0.65)
            else
                t.colors.divider;
            panel_ctx.drawRect(sep2_rect, .{ .fill = divider_color });
            cursor_y = sep2_rect.max[1] + separator_gap;

            const composer_rect = draw_context.Rect.fromMinSize(.{ panel_rect.min[0], cursor_y }, .{ panel_rect.size()[0], input_height });

            if (composer_rect.size()[1] > 0.0) {
                if (is_busy) {
                    drawBusyComposerAccent(&panel_ctx, composer_rect);
                }
                if (input_panel.draw(allocator, &panel_ctx, composer_rect, queue, true, has_session, composer_status_text)) |message| {
                    action.send_message = message;
                }
            }

            if (panel_state.copy_context_menu_open) {
                const menu_action = drawCopyContextMenu(
                    &panel_ctx,
                    queue,
                    panel_rect,
                    has_session,
                    has_selection,
                    &panel_state.copy_context_menu_open,
                    panel_state.copy_context_menu_anchor,
                );
                switch (menu_action) {
                    .copy_selection => {
                        if (panel_state.select_copy_mode) {
                            ChatView.copySelectCopySelectionToClipboard(allocator, &panel_state.view);
                        } else {
                            ChatView.copySelectionToClipboard(allocator, &panel_state.view, messages, stream_text, inbox, show_tool_output);
                        }
                        panel_state.copy_context_menu_open = false;
                    },
                    .copy_all => {
                        ChatView.copyAllToClipboard(allocator, messages, stream_text, inbox, show_tool_output);
                        panel_state.copy_context_menu_open = false;
                    },
                    .none => {},
                }
            }

            if (panel_state.session_picker_open) {
                if (header_action.picker_rect) |picker_rect| {
                    const selection = drawSessionPicker(
                        allocator,
                        &panel_ctx,
                        queue,
                        sessions,
                        agent_id,
                        session_key,
                        panel_state.selected_session_id,
                        picker_rect,
                        &panel_state.show_system_sessions,
                    );
                    if (selection.key) |key| {
                        action.select_session = key;
                        action.select_session_id = selection.session_id;
                        clearSelectedSessionId(allocator, panel_state);
                        if (action.select_session_id) |sid| {
                            panel_state.selected_session_id = allocator.dupe(u8, sid) catch null;
                        }
                        panel_state.session_picker_open = false;
                    } else {
                        if (selection.session_id) |sid| allocator.free(sid);
                        for (queue.events.items) |evt| {
                            switch (evt) {
                                .mouse_down => |md| {
                                    if (md.button != .left) continue;
                                    if (picker_rect.contains(md.pos)) continue;
                                    const menu_rect = pickerMenuRect(&panel_ctx, picker_rect);
                                    if (!menu_rect.contains(md.pos)) {
                                        panel_state.session_picker_open = false;
                                    }
                                },
                                else => {},
                            }
                        }
                    }
                } else {
                    panel_state.session_picker_open = false;
                }
            }

            if (header_action.request_new_chat) {
                clearSelectedSessionId(allocator, panel_state);
                action.new_chat_session_key = resolveNewChatSessionKey(allocator, sessions, agent_id, session_key);
            }

            action.open_activity_panel = header_action.open_activity_panel;
            action.open_approvals_panel = header_action.open_approvals_panel;

            return action;
        }

        fn drawHeader(
            ctx: *draw_context.DrawContext,
            rect: draw_context.Rect,
            queue: *input_state.InputQueue,
            agent_id: []const u8,
            agent_icon: []const u8,
            agent_name: []const u8,
            status_text: []const u8,
            is_busy: bool,
            busy_phase: u8,
            sessions: []const Session,
            session_key: ?[]const u8,
            current_session_id: ?[]const u8,
            has_session: bool,
            select_copy_mode_ref: *bool,
            debug_tier: debug_visibility.DebugVisibilityTier,
            activity_warn_error_count: usize,
            pending_approvals_count: usize,
            session_picker_open_ref: *bool,
            control_height: f32,
        ) HeaderAction {
            _ = agent_id;
            _ = agent_icon;
            _ = agent_name;
            _ = status_text;
            _ = is_busy;
            _ = busy_phase;
            
            const t = ctx.theme;
            ctx.pushClip(rect);
            defer ctx.popClip();

            const top_pad = t.spacing.xs;
            const start_x = rect.min[0] + t.spacing.sm;
            const start_y = rect.min[1] + top_pad;
            const row_h = @max(ctx.lineHeight(), control_height);

            const picker_w_desired = std.math.clamp(rect.size()[0] * 0.34, 180.0, 360.0);
            const picker_w_min: f32 = 96.0;
            const picker_h = @max(control_height, row_h);
            const new_label = "New Chat";
            const new_w = ctx.measureText(new_label, 0.0)[0] + t.spacing.sm * 2.0;
            const right_bound = rect.max[0] - t.spacing.sm;

            const controls_y = start_y;
            const box_size = @min(control_height, row_h);
            const checkbox_spacing = t.spacing.xs;
            const item_spacing = t.spacing.xs;

            const gap = t.spacing.sm;

            const select_label = "Raw";
            const select_width = box_size + checkbox_spacing + ctx.measureText(select_label, 0.0)[0];

            var vis_buf: [48]u8 = undefined;
            const vis_label = std.fmt.bufPrint(&vis_buf, "Vis: {s}", .{debug_tier.label()}) catch "Vis";
            const vis_w = ctx.measureText(vis_label, 0.0)[0] + t.spacing.sm * 2.0;

            var activity_buf: [48]u8 = undefined;
            const activity_label: []const u8 = if (activity_warn_error_count > 0)
                (std.fmt.bufPrint(&activity_buf, "Activity {d}", .{activity_warn_error_count}) catch "Activity")
            else
                "Activity";
            const activity_w = ctx.measureText(activity_label, 0.0)[0] + t.spacing.sm * 2.0;

            var approvals_buf: [56]u8 = undefined;
            const approvals_label: []const u8 = if (pending_approvals_count > 0)
                (std.fmt.bufPrint(&approvals_buf, "Approvals {d}", .{pending_approvals_count}) catch "Approvals")
            else
                "Approvals";
            const approvals_w = ctx.measureText(approvals_label, 0.0)[0] + t.spacing.sm * 2.0;

            const reserve_right: f32 = picker_w_min;

            var show_raw = true;
            var show_vis = true;
            var show_activity = true;
            var show_approvals = true;

            const desired_all = select_width + item_spacing + vis_w + item_spacing + activity_w + item_spacing + approvals_w;
            if (start_x + desired_all + gap + reserve_right > right_bound) {
                show_approvals = false;
            }
            const desired_no_approvals = select_width + item_spacing + vis_w + item_spacing + activity_w;
            if (start_x + desired_no_approvals + gap + reserve_right > right_bound) {
                show_activity = false;
            }
            const desired_no_activity = select_width + item_spacing + vis_w;
            if (start_x + desired_no_activity + gap + reserve_right > right_bound) {
                show_vis = false;
            }
            if (start_x + select_width + gap + reserve_right > right_bound) {
                show_raw = false;
                show_vis = false;
                show_activity = false;
                show_approvals = false;
            }

            var open_activity_panel = false;
            var open_approvals_panel = false;

            var controls_end = start_x;
            if (show_raw) {
                const select_rect = draw_context.Rect.fromMinSize(.{ controls_end, controls_y }, .{ select_width, control_height });
                _ = widgets.checkbox.draw(ctx, select_rect, select_label, select_copy_mode_ref, queue, .{ .disabled = !has_session });
                controls_end = select_rect.max[0];
            }

            if (show_vis) {
                const vis_rect = draw_context.Rect.fromMinSize(.{ controls_end + item_spacing, start_y - t.spacing.xs * 0.2 }, .{ vis_w, picker_h });
                if (widgets.button.draw(ctx, vis_rect, vis_label, queue, .{ .variant = .secondary })) {
                    debug_visibility.current_tier = debug_visibility.cycle(debug_visibility.current_tier);
                }
                controls_end = vis_rect.max[0];
            }

            if (show_activity) {
                const act_rect = draw_context.Rect.fromMinSize(.{ controls_end + item_spacing, start_y - t.spacing.xs * 0.2 }, .{ activity_w, picker_h });
                if (widgets.button.draw(ctx, act_rect, activity_label, queue, .{ .variant = .secondary })) {
                    open_activity_panel = true;
                }
                controls_end = act_rect.max[0];
            }

            if (show_approvals) {
                const appr_rect = draw_context.Rect.fromMinSize(.{ controls_end + item_spacing, start_y - t.spacing.xs * 0.2 }, .{ approvals_w, picker_h });
                if (widgets.button.draw(ctx, appr_rect, approvals_label, queue, .{ .variant = .secondary })) {
                    open_approvals_panel = true;
                }
                controls_end = appr_rect.max[0];
            }

            var right_cursor = right_bound;

            var picker_rect_opt: ?draw_context.Rect = null;
            var request_new_chat = false;
            const available = right_cursor - (controls_end + gap);
            if (available >= 64.0) {
                var picker_available = available;
                var show_new = false;
                if (available >= picker_w_min + t.spacing.xs + new_w) {
                    show_new = true;
                    picker_available -= new_w + t.spacing.xs;
                }

                if (picker_available >= 64.0) {
                    const picker_w = @max(64.0, @min(picker_w_desired, picker_available));
                    const picker_x = right_cursor - picker_w;
                    const picker_rect = draw_context.Rect.fromMinSize(.{ picker_x, start_y - t.spacing.xs * 0.2 }, .{ picker_w, picker_h });

                    var picker_label_buf: [160]u8 = undefined;
                    const picker_label = resolveCurrentSessionLabel(sessions, session_key, current_session_id, &picker_label_buf);
                    const picker_text_max = @max(0.0, picker_rect.size()[0] - t.spacing.sm * 2.0 - ctx.measureText(" v", 0.0)[0]);
                    var fitted_picker_buf: [192]u8 = undefined;
                    const fitted_picker = fitTextEnd(ctx, picker_label, picker_text_max, &fitted_picker_buf);
                    var button_label_buf: [224]u8 = undefined;
                    const button_label = if (fitted_picker.len > 0)
                        std.fmt.bufPrint(&button_label_buf, "{s} v", .{fitted_picker}) catch "v"
                    else
                        "v";
                    if (widgets.button.draw(ctx, picker_rect, button_label, queue, .{ .variant = .secondary })) {
                        session_picker_open_ref.* = !session_picker_open_ref.*;
                    }
                    picker_rect_opt = picker_rect;

                    right_cursor = picker_rect.min[0] - t.spacing.xs;
                    if (show_new and right_cursor - new_w >= controls_end + gap) {
                        const new_button_rect = draw_context.Rect.fromMinSize(
                            .{ right_cursor - new_w, start_y - t.spacing.xs * 0.2 },
                            .{ new_w, picker_h },
                        );
                        if (widgets.button.draw(ctx, new_button_rect, new_label, queue, .{ .variant = .secondary })) {
                            request_new_chat = true;
                        }
                    }
                }
            }

            return .{
                .picker_rect = picker_rect_opt,
                .request_new_chat = request_new_chat,
                .open_activity_panel = open_activity_panel,
                .open_approvals_panel = open_approvals_panel,
            };
        }

        fn drawSessionPicker(
            allocator: std.mem.Allocator,
            ctx: *draw_context.DrawContext,
            queue: *input_state.InputQueue,
            sessions: []const Session,
            agent_id: []const u8,
            current_session: ?[]const u8,
            current_session_id: ?[]const u8,
            picker_rect: draw_context.Rect,
            show_system_ref: *bool,
        ) SessionSelection {
            _ = allocator;
            _ = agent_id;
            _ = current_session_id;
            
            const t = ctx.theme;
            const menu_rect = pickerMenuRect(ctx, picker_rect);
            ctx.drawRoundedRect(menu_rect, t.radius.sm, .{
                .fill = t.colors.surface,
                .stroke = t.colors.border,
                .thickness = 1.0,
            });

            const padding = t.spacing.xs;
            var cursor_y = menu_rect.min[1] + padding;

            const toggle_label = "Show system sessions";
            const toggle_width = ctx.lineHeight() + t.spacing.xs + ctx.measureText(toggle_label, 0.0)[0];
            const toggle_height = @max(ctx.lineHeight(), 20.0);
            const toggle_rect = draw_context.Rect.fromMinSize(.{ menu_rect.min[0] + padding, cursor_y }, .{ toggle_width, toggle_height });
            _ = widgets.checkbox.draw(ctx, toggle_rect, toggle_label, show_system_ref, queue, .{});
            cursor_y += toggle_height + t.spacing.xs;

            const heading_h = ctx.lineHeight() + t.spacing.xs * 0.5;
            _ = heading_h;
            const group_gap = t.spacing.xs;
            _ = group_gap;
            const row_h = ctx.lineHeight() * 2.0 + t.spacing.xs;
            const row_gap = t.spacing.xs * 0.5;
            const menu_bottom = menu_rect.max[1] - padding;

            var ordinal: usize = 0;
            
            // Simplified session list - just show keys
            for (sessions) |session| {
                if (cursor_y + row_h > menu_bottom) break;

                const row_rect = draw_context.Rect.fromMinSize(
                    .{ menu_rect.min[0] + padding, cursor_y },
                    .{ menu_rect.size()[0] - padding * 2.0, row_h },
                );
                
                const selected = current_session != null and std.mem.eql(u8, current_session.?, session.key);
                const clicked = drawPickerTextRow(ctx, queue, row_rect, session.key, "Session", selected);
                
                if (clicked) {
                    return .{
                        .key = ctx.allocator.dupe(u8, session.key) catch null,
                        .session_id = null,
                    };
                }
                ordinal += 1;
                cursor_y += row_h + row_gap;
            }

            return .{};
        }

        fn resolveCurrentSessionLabel(
            sessions: []const Session,
            session_key: ?[]const u8,
            current_session_id: ?[]const u8,
            label_buf: []u8,
        ) []const u8 {
            _ = sessions;
            _ = current_session_id;
            if (session_key == null) return "Select session";
            return std.fmt.bufPrint(label_buf, "{s}", .{session_key.?}) catch "Session";
        }

        fn resolveNewChatSessionKey(
            allocator: std.mem.Allocator,
            sessions: []const Session,
            agent_id: []const u8,
            current_session: ?[]const u8,
        ) ?[]u8 {
            _ = agent_id;
            if (current_session) |key| {
                return allocator.dupe(u8, key) catch null;
            }
            
            // Pick first session or create new
            if (sessions.len > 0) {
                return allocator.dupe(u8, sessions[0].key) catch null;
            }
            return null;
        }
    };
}

// Helper types and functions that don't depend on Message/Session
const SessionState = struct {
    messages: std.ArrayList(std.json.Value),
    stream_text: ?[]const u8,
    messages_loading: bool,
    stream_run_id: ?[]const u8,
    awaiting_reply: bool,
};

fn isToolRole(role: []const u8) bool {
    return std.mem.startsWith(u8, role, "tool") or std.mem.eql(u8, role, "toolResult");
}

fn looksWarnOrError(content: []const u8) bool {
    return containsIgnoreCase(content, "error") or
        containsIgnoreCase(content, "failed") or
        containsIgnoreCase(content, "exception") or
        containsIgnoreCase(content, "warning") or
        containsIgnoreCase(content, "warn");
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;

    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var j: usize = 0;
        while (j < needle.len) : (j += 1) {
            if (std.ascii.toLower(haystack[i + j]) != std.ascii.toLower(needle[j])) break;
        }
        if (j == needle.len) return true;
    }
    return false;
}

fn pickerMenuRect(ctx: *draw_context.DrawContext, picker_rect: draw_context.Rect) draw_context.Rect {
    const t = ctx.theme;
    const w = std.math.clamp(picker_rect.size()[0] + 80.0, 260.0, 460.0);
    const h = std.math.clamp(ctx.lineHeight() * 8.5, 190.0, 340.0);
    const x = picker_rect.max[0] - w;
    const y = picker_rect.max[1] + t.spacing.xs;
    return draw_context.Rect.fromMinSize(.{ x, y }, .{ w, h });
}

fn drawPickerTextRow(
    ctx: *draw_context.DrawContext,
    queue: *input_state.InputQueue,
    rect: draw_context.Rect,
    primary: []const u8,
    secondary: []const u8,
    selected: bool,
) bool {
    const t = ctx.theme;
    const hovered = rect.contains(queue.state.mouse_pos);
    if (selected or hovered) {
        const base = if (selected) t.colors.primary else t.colors.surface;
        const alpha: f32 = if (selected) 0.12 else 0.08;
        ctx.drawRoundedRect(rect, t.radius.sm, .{ .fill = .{ base[0], base[1], base[2], alpha } });
    }

    const left = rect.min[0] + t.spacing.xs;
    const text_max = @max(0.0, rect.size()[0] - t.spacing.xs * 2.0);
    var primary_fit_buf: [80]u8 = undefined;
    var secondary_fit_buf: [80]u8 = undefined;
    const primary_fit = fitTextEnd(ctx, primary, text_max, &primary_fit_buf);
    const secondary_fit = fitTextEnd(ctx, secondary, text_max, &secondary_fit_buf);
    ctx.drawText(primary_fit, .{ left, rect.min[1] + t.spacing.xs * 0.2 }, .{ .color = t.colors.text_primary });
    ctx.drawText(secondary_fit, .{ left, rect.min[1] + ctx.lineHeight() + t.spacing.xs * 0.2 }, .{ .color = t.colors.text_secondary });

    for (queue.events.items) |evt| {
        switch (evt) {
            .mouse_up => |mu| {
                if (mu.button == .left and rect.contains(mu.pos)) {
                    if (queue.state.pointer_kind == .mouse or !queue.state.pointer_dragging) {
                        return true;
                    }
                }
            },
            else => {},
        }
    }
    return false;
}

fn fitTextEnd(
    ctx: *draw_context.DrawContext,
    text: []const u8,
    max_width: f32,
    buf: []u8,
) []const u8 {
    if (text.len == 0) return "";
    if (max_width <= 0.0) return "";
    if (ctx.measureText(text, 0.0)[0] <= max_width) return text;

    const ellipsis = "...";
    const ellipsis_w = ctx.measureText(ellipsis, 0.0)[0];
    if (ellipsis_w > max_width) return "";
    if (buf.len <= ellipsis.len) return ellipsis;

    var low: usize = 0;
    var high: usize = @min(text.len, buf.len - ellipsis.len - 1);
    var best: usize = 0;
    while (low <= high) {
        const mid = low + (high - low) / 2;
        const candidate = std.fmt.bufPrint(buf, "{s}{s}", .{ text[0..mid], ellipsis }) catch ellipsis;
        const w = ctx.measureText(candidate, 0.0)[0];
        if (w <= max_width) {
            best = mid;
            low = mid + 1;
        } else {
            if (mid == 0) break;
            high = mid - 1;
        }
    }

    if (best == 0) return ellipsis;
    return std.fmt.bufPrint(buf, "{s}{s}", .{ text[0..best], ellipsis }) catch ellipsis;
}

fn clearSelectedSessionId(allocator: std.mem.Allocator, panel_state: *workspace.ChatPanel) void {
    _ = allocator;
    panel_state.selected_session_id = null;
}

fn normalizeSelectedSessionId(
    allocator: std.mem.Allocator,
    panel_state: *workspace.ChatPanel,
    session_key: ?[]const u8,
    sessions: anytype,
) void {
    _ = allocator;
    _ = panel_state;
    _ = session_key;
    _ = sessions;
}

fn drawBusyComposerAccent(ctx: *draw_context.DrawContext, composer_rect: draw_context.Rect) void {
    _ = ctx;
    _ = composer_rect;
}

fn drawCopyContextMenu(
    ctx: *draw_context.DrawContext,
    queue: *input_state.InputQueue,
    panel_rect: draw_context.Rect,
    has_session: bool,
    has_selection: bool,
    open_ref: *bool,
    anchor: [2]f32,
) CopyContextMenuAction {
    _ = panel_rect;
    _ = has_session;
    _ = has_selection;
    _ = open_ref;
    _ = anchor;
    _ = ctx;
    _ = queue;
    return .none;
}

// Backward compatibility: DefaultChatPanel using local protocol types
const protocol_types = @import("../../protocol/types.zig");
pub const DefaultChatPanel = ChatPanel(protocol_types.ChatMessage, protocol_types.Session);

// Re-export draw function for compatibility
pub fn draw(
    allocator: std.mem.Allocator,
    panel_state: anytype,
    agent_id: []const u8,
    session_key: ?[]const u8,
    session_state: anytype,
    agent_icon: []const u8,
    agent_name: []const u8,
    sessions: anytype,
    inbox: anytype,
    pending_approvals_count: usize,
    rect_override: anytype,
) ChatPanelAction {
    // Extract messages from session_state if available
    const messages = if (session_state) |s| s.messages.items else &[_]protocol_types.ChatMessage{};
    const stream_text = if (session_state) |s| s.stream_text else null;
    
    return DefaultChatPanel.draw(
        allocator,
        panel_state,
        agent_id,
        session_key,
        messages,
        stream_text,
        inbox,
        agent_icon,
        agent_name,
        sessions,
        pending_approvals_count,
        rect_override,
        null,
    );
}
