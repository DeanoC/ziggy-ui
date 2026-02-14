//! SDL3 platform backend
const std = @import("std");
const sdl3 = @import("sdl3");
const PlatformBackend = @import("platform.zig").PlatformBackend;
const Capabilities = @import("platform.zig").Capabilities;
const MonitorInfo = @import("platform.zig").MonitorInfo;
const WindowConfig = @import("../window/window.zig").WindowConfig;
const WindowId = @import("../window/window.zig").WindowId;
const WindowMode = @import("../window/window.zig").WindowMode;
const Event = @import("../core/events.zig").Event;

// Legacy C-API handle used by ZiggyStarClaw UI modules.
pub const c = @import("zsc").platform.sdl3.c;

/// SDL3 platform state
var sdl_initialized = false;
var windows: std.AutoHashMap(WindowId, *sdl3.Window) = undefined;
var next_window_id: WindowId = 1;

pub fn init() !void {
    if (sdl_initialized) return;

    try sdl3.init(.{ .video = true, .events = true });
    sdl_initialized = true;

    windows = std.AutoHashMap(WindowId, *sdl3.Window).init(std.heap.page_allocator);
}

pub fn deinit() void {
    if (!sdl_initialized) return;

    var it = windows.valueIterator();
    while (it.next()) |window_ptr| {
        sdl3.destroyWindow(window_ptr.*);
    }
    windows.deinit();

    sdl3.quit();
    sdl_initialized = false;
}

pub fn getCapabilities() Capabilities {
    return .{
        .multiple_windows = true,
        .drag_and_drop = true,
        .clipboard = true,
        .file_dialogs = false, // Would need native platform code
        .high_dpi = true,
        .vsync_control = true,
    };
}

pub fn createWindow(config: WindowConfig, userdata: ?*anyopaque) !WindowId {
    _ = userdata;

    var flags: sdl3.WindowFlags = .{
        .resizable = config.resizable,
        .borderless = config.borderless,
        .transparent = config.transparent,
        .high_pixel_density = true,
    };

    switch (config.mode) {
        .fullscreen => flags.fullscreen = true,
        .maximized => flags.maximized = true,
        else => {},
    }

    const window = try sdl3.createWindow(config.title, @intCast(config.width), @intCast(config.height), flags);

    const id = next_window_id;
    next_window_id += 1;

    try windows.put(id, window);

    return id;
}

pub fn destroyWindow(window_id: WindowId) void {
    if (windows.fetchRemove(window_id)) |kv| {
        sdl3.destroyWindow(kv.value);
    }
}

pub fn showWindow(window_id: WindowId) void {
    if (windows.get(window_id)) |window| {
        sdl3.showWindow(window);
    }
}

pub fn hideWindow(window_id: WindowId) void {
    if (windows.get(window_id)) |window| {
        sdl3.hideWindow(window);
    }
}

pub fn setWindowTitle(window_id: WindowId, title: []const u8) void {
    if (windows.get(window_id)) |window| {
        sdl3.setWindowTitle(window, title);
    }
}

pub fn setWindowSize(window_id: WindowId, width: u32, height: u32) void {
    if (windows.get(window_id)) |window| {
        sdl3.setWindowSize(window, @intCast(width), @intCast(height));
    }
}

pub fn setWindowPosition(window_id: WindowId, x: i32, y: i32) void {
    if (windows.get(window_id)) |window| {
        sdl3.setWindowPosition(window, x, y);
    }
}

pub fn setWindowMode(window_id: WindowId, mode: WindowMode) void {
    if (windows.get(window_id)) |window| {
        switch (mode) {
            .fullscreen => sdl3.setWindowFullscreen(window, true),
            .windowed => sdl3.setWindowFullscreen(window, false),
            .maximized => sdl3.maximizeWindow(window),
            .minimized => sdl3.minimizeWindow(window),
        }
    }
}

pub fn getWindowSize(window_id: WindowId) struct { width: u32, height: u32 } {
    if (windows.get(window_id)) |window| {
        const size = sdl3.getWindowSize(window);
        return .{ .width = @intCast(size.width), .height = @intCast(size.height) };
    }
    return .{ .width = 0, .height = 0 };
}

pub fn getFramebufferSize(window_id: WindowId) struct { width: u32, height: u32 } {
    if (windows.get(window_id)) |window| {
        const size = sdl3.getWindowSizeInPixels(window);
        return .{ .width = @intCast(size.width), .height = @intCast(size.height) };
    }
    return .{ .width = 0, .height = 0 };
}

pub fn getWindowContentScale(window_id: WindowId) struct { x: f32, y: f32 } {
    if (windows.get(window_id)) |window| {
        // Calculate scale from window size vs framebuffer size
        const window_size = sdl3.getWindowSize(window);
        const fb_size = sdl3.getWindowSizeInPixels(window);

        const scale_x = @as(f32, @floatFromInt(fb_size.width)) / @as(f32, @floatFromInt(window_size.width));
        const scale_y = @as(f32, @floatFromInt(fb_size.height)) / @as(f32, @floatFromInt(window_size.height));

        return .{ .x = scale_x, .y = scale_y };
    }
    return .{ .x = 1.0, .y = 1.0 };
}

pub fn requestWindowAttention(window_id: WindowId) void {
    if (windows.get(window_id)) |window| {
        sdl3.flashWindow(window, .briefly);
    }
}

pub fn pollEvent(event: *Event) bool {
    var sdl_event: sdl3.Event = undefined;

    if (!sdl3.pollEvent(&sdl_event)) {
        return false;
    }

    event.* = convertEvent(sdl_event);
    return true;
}

pub fn waitEvent(event: *Event) void {
    var sdl_event: sdl3.Event = undefined;
    sdl3.waitEvent(&sdl_event);
    event.* = convertEvent(sdl_event);
}

fn convertEvent(sdl_event: sdl3.Event) Event {
    return switch (sdl_event.type) {
        .quit => .{ .window_close = .{ .window_id = 0 } },

        .window => |we| switch (we.event) {
            .close => .{ .window_close = .{ .window_id = @intCast(we.window_id) } },
            .resized => .{ .window_resize = .{
                .width = @intCast(we.data1),
                .height = @intCast(we.data2),
                .window_id = @intCast(we.window_id),
            } },
            .focus_gained => .{ .window_focus = .{ .focused = true, .window_id = @intCast(we.window_id) } },
            .focus_lost => .{ .window_focus = .{ .focused = false, .window_id = @intCast(we.window_id) } },
            else => .{ .window_close = .{ .window_id = 0 } }, // Dummy
        },

        .mouse_motion => |me| .{ .mouse_move = .{
            .pos = .{ @floatFromInt(me.x), @floatFromInt(me.y) },
            .delta = .{ @floatFromInt(me.xrel), @floatFromInt(me.yrel) },
            .timestamp = @intCast(me.timestamp),
        } },

        .mouse_button_down => |me| .{ .mouse_down = .{
            .button = convertMouseButton(me.button),
            .pos = .{ @floatFromInt(me.x), @floatFromInt(me.y) },
            .modifiers = convertKeyModifiers(me.mod),
            .timestamp = @intCast(me.timestamp),
        } },

        .mouse_button_up => |me| .{ .mouse_up = .{
            .button = convertMouseButton(me.button),
            .pos = .{ @floatFromInt(me.x), @floatFromInt(me.y) },
            .modifiers = convertKeyModifiers(me.mod),
            .timestamp = @intCast(me.timestamp),
        } },

        .mouse_wheel => |we| .{
            .mouse_scroll = .{
                .delta_x = @floatFromInt(we.x),
                .delta_y = @floatFromInt(we.y),
                .pos = .{ 0, 0 }, // SDL doesn't provide mouse pos with wheel
                .modifiers = convertKeyModifiers(we.mod),
                .timestamp = @intCast(we.timestamp),
            },
        },

        .key_down => |ke| .{ .key_down = .{
            .key = convertKeyCode(ke.keycode),
            .scancode = @intCast(ke.scancode),
            .modifiers = convertKeyModifiers(ke.mod),
            .repeat = ke.repeat,
            .timestamp = @intCast(ke.timestamp),
        } },

        .key_up => |ke| .{ .key_up = .{
            .key = convertKeyCode(ke.keycode),
            .scancode = @intCast(ke.scancode),
            .modifiers = convertKeyModifiers(ke.mod),
            .repeat = false,
            .timestamp = @intCast(ke.timestamp),
        } },

        .text_input => |te| .{
            .char_input = .{
                .codepoint = te.text[0], // Simplified - would need UTF-8 decoding
                .timestamp = 0,
            },
        },

        else => .{ .window_close = .{ .window_id = 0 } }, // Dummy
    };
}

fn convertMouseButton(button: u8) @import("../core/events.zig").MouseButton {
    return switch (button) {
        1 => .left,
        2 => .middle,
        3 => .right,
        4 => .back,
        5 => .forward,
        else => .left,
    };
}

fn convertKeyModifiers(mod: u16) @import("../core/events.zig").Modifiers {
    return @import("../core/events.zig").Modifiers.fromSDL(mod);
}

fn convertKeyCode(keycode: i32) @import("../core/events.zig").Key {
    // Simplified mapping - full implementation would map all SDL keycodes
    return switch (keycode) {
        0x0000000d => .enter,
        0x0000001b => .escape,
        0x00000008 => .backspace,
        0x00000009 => .tab,
        0x00000020 => .space,
        0x00000061...0x0000007a => |k| @enumFromInt(@intFromEnum(@import("../core/events.zig").Key.a) + @as(u8, @intCast(k)) - 0x61),
        0x00000030...0x00000039 => |k| @enumFromInt(@intFromEnum(@import("../core/events.zig").Key.num_0) + @as(u8, @intCast(k)) - 0x30),
        0x40000052 => .up,
        0x40000051 => .down,
        0x40000050 => .left,
        0x4000004f => .right,
        else => .unknown,
    };
}

pub fn getTime() f64 {
    return @as(f64, @floatFromInt(sdl3.getTicksNS())) / 1e9;
}

pub fn sleep(seconds: f64) void {
    sdl3.delayNS(@intFromFloat(seconds * 1e9));
}

pub fn getClipboardText(allocator: std.mem.Allocator) ?[]const u8 {
    const text = sdl3.getClipboardText() orelse return null;
    defer sdl3.free(text);

    const len = std.mem.len(text);
    const copy = allocator.alloc(u8, len) catch return null;
    @memcpy(copy, text[0..len]);
    return copy;
}

pub fn setClipboardText(text: []const u8) void {
    sdl3.setClipboardText(text);
}

pub fn getPrimaryMonitor() ?MonitorInfo {
    const display_id = sdl3.getPrimaryDisplay();
    const name = sdl3.getDisplayName(display_id) orelse "Primary";

    const bounds = sdl3.getDisplayBounds(display_id) orelse return null;

    return .{
        .name = name,
        .x = bounds.x,
        .y = bounds.y,
        .width = @intCast(bounds.w),
        .height = @intCast(bounds.h),
        .scale_x = 1.0,
        .scale_y = 1.0,
        .refresh_rate = 60,
    };
}

pub fn getMonitors(allocator: std.mem.Allocator) ![]MonitorInfo {
    const displays = sdl3.getDisplays() orelse return &[_]MonitorInfo{};
    defer sdl3.free(displays);

    var list = std.ArrayList(MonitorInfo).init(allocator);
    errdefer list.deinit();

    for (displays) |display_id| {
        const name = sdl3.getDisplayName(display_id) orelse continue;
        const bounds = sdl3.getDisplayBounds(display_id) orelse continue;

        try list.append(.{
            .name = name,
            .x = bounds.x,
            .y = bounds.y,
            .width = @intCast(bounds.w),
            .height = @intCast(bounds.h),
            .scale_x = 1.0,
            .scale_y = 1.0,
            .refresh_rate = 60,
        });
    }

    return list.toOwnedSlice();
}

/// Get the SDL3 platform backend interface
pub fn getBackend() PlatformBackend {
    return .{
        .init = init,
        .deinit = deinit,
        .getCapabilities = getCapabilities,
        .createWindow = createWindow,
        .destroyWindow = destroyWindow,
        .showWindow = showWindow,
        .hideWindow = hideWindow,
        .setWindowTitle = setWindowTitle,
        .setWindowSize = setWindowSize,
        .setWindowPosition = setWindowPosition,
        .setWindowMode = setWindowMode,
        .getWindowSize = getWindowSize,
        .getFramebufferSize = getFramebufferSize,
        .getWindowContentScale = getWindowContentScale,
        .requestWindowAttention = requestWindowAttention,
        .pollEvent = pollEvent,
        .waitEvent = waitEvent,
        .getTime = getTime,
        .sleep = sleep,
        .getClipboardText = getClipboardText,
        .setClipboardText = setClipboardText,
        .getPrimaryMonitor = getPrimaryMonitor,
        .getMonitors = getMonitors,
    };
}
