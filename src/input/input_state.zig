//! Input state management
const std = @import("std");

pub const InputState = struct {
    mouse_pos: [2]f32 = .{ 0, 0 },
    mouse_down: bool = false,
    mouse_down_left: bool = false,
    mouse_down_right: bool = false,
    mouse_down_middle: bool = false,
};

pub const InputQueue = struct {
    events: std.ArrayList(InputEvent),
    state: InputState = .{},
    
    pub fn init(allocator: std.mem.Allocator) InputQueue {
        return .{
            .events = std.ArrayList(InputEvent).init(allocator),
        };
    }
    
    pub fn deinit(self: *InputQueue, allocator: std.mem.Allocator) void {
        self.events.deinit(allocator);
    }
    
    pub fn clear(self: *InputQueue) void {
        self.events.clearRetainingCapacity();
    }
    
    pub fn push(self: *InputQueue, allocator: std.mem.Allocator, event: InputEvent) !void {
        try self.events.append(event);
    }
};

pub const InputEvent = union(enum) {
    mouse_move: MouseMoveEvent,
    mouse_down: MouseButtonEvent,
    mouse_up: MouseButtonEvent,
    key_down: KeyEvent,
    key_up: KeyEvent,
    char_input: CharInputEvent,
};

pub const MouseMoveEvent = struct {
    pos: [2]f32,
    delta: [2]f32 = .{ 0, 0 },
};

pub const MouseButtonEvent = struct {
    button: MouseButton,
    pos: [2]f32,
};

pub const MouseButton = enum {
    left,
    right,
    middle,
    back,
    forward,
};

pub const KeyEvent = struct {
    key: Key,
    scancode: i32 = 0,
    modifiers: Modifiers = .{},
    repeat: bool = false,
};

pub const Key = enum {
    unknown,
    a, b, c, d, e, f, g, h, i, j, k, l, m,
    n, o, p, q, r, s, t, u, v, w, x, y, z,
    num_0, num_1, num_2, num_3, num_4,
    num_5, num_6, num_7, num_8, num_9,
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,
    escape, enter, return_, tab, backspace, insert, delete,
    right, left, down, up,
    page_up, page_down, home, end,
    caps_lock, scroll_lock, num_lock,
    print_screen, pause,
    space,
    apostrophe, comma, minus, period, slash, semicolon,
    equal, bracket_left, backslash, bracket_right, grave,
    
    kp_0, kp_1, kp_2, kp_3, kp_4,
    kp_5, kp_6, kp_7, kp_8, kp_9,
    kp_decimal, kp_divide, kp_multiply,
    kp_subtract, kp_add, kp_enter, kp_equal,
    
    left_shift, left_ctrl, left_alt, left_super,
    right_shift, right_ctrl, right_alt, right_super,
    
    menu,
};

pub const Modifiers = packed struct {
    shift: bool = false,
    ctrl: bool = false,
    alt: bool = false,
    meta: bool = false,
    
    pub fn fromSDL(sdl_mods: u16) Modifiers {
        return .{
            .shift = (sdl_mods & 0x0001) != 0 or (sdl_mods & 0x0002) != 0,
            .ctrl = (sdl_mods & 0x0040) != 0 or (sdl_mods & 0x0080) != 0,
            .alt = (sdl_mods & 0x0100) != 0 or (sdl_mods & 0x0200) != 0,
            .meta = (sdl_mods & 0x0400) != 0 or (sdl_mods & 0x0800) != 0,
        };
    }
};

pub const CharInputEvent = struct {
    codepoint: u32,
};
